from fastapi import (
    FastAPI,
    HTTPException,
    UploadFile,
    File,
    Form,
)

from pydantic import BaseModel

import psycopg2

from passlib.hash import bcrypt

from fastapi.staticfiles import StaticFiles

import shutil

import uuid

import json

import urllib.parse

import urllib.request

import random

from datetime import datetime, timedelta

from pathlib import Path

from typing import Optional


app = FastAPI()

BASE_DIR = Path(__file__).resolve().parent
UPLOADS_DIR = BASE_DIR / "uploads"
POSTS_DIR = BASE_DIR / "Posts"

UPLOADS_DIR.mkdir(exist_ok=True)
POSTS_DIR.mkdir(exist_ok=True)

# ⭐ uploads フォルダ公開
app.mount(
    "/uploads",
    StaticFiles(directory=UPLOADS_DIR),
    name="uploads"
)
app.mount(
    "/Posts",
    StaticFiles(directory=POSTS_DIR),
    name="Posts"
)


def get_db_connection():

    return psycopg2.connect(
        dbname="account_manage",
        user="ryohe1101",
        password="",
        host="localhost"
    )


def ensure_posts_table():

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS posts (
            id SERIAL PRIMARY KEY,
            user_email TEXT NOT NULL,
            image_path TEXT NOT NULL,
            shop_name TEXT,
            category TEXT NOT NULL,
            price_range TEXT NOT NULL,
            location TEXT NOT NULL,
            comment TEXT NOT NULL,
            tags TEXT,
            latitude DOUBLE PRECISION,
            longitude DOUBLE PRECISION,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )

    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION")
    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION")
    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()")
    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS shop_name TEXT")
    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS tags TEXT")

    conn.commit()

    cur.close()
    conn.close()


def ensure_release_tables():

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT FALSE")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_code TEXT")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verification_expires_at TIMESTAMP")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS password_reset_code TEXT")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS password_reset_expires_at TIMESTAMP")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS terms_accepted_at TIMESTAMP")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_accepted_at TIMESTAMP")
    cur.execute("ALTER TABLE users ADD COLUMN IF NOT EXISTS location_consent_at TIMESTAMP")

    cur.execute(
        """
        SELECT COUNT(*)
        FROM (
            SELECT LOWER(TRIM(username)) AS normalized_username
            FROM users
            WHERE COALESCE(TRIM(username), '') <> ''
            GROUP BY LOWER(TRIM(username))
            HAVING COUNT(*) > 1
        ) duplicated_usernames
        """
    )

    duplicated_username_count = cur.fetchone()[0]

    if duplicated_username_count == 0:

        cur.execute(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS users_username_unique
            ON users (LOWER(TRIM(username)))
            WHERE COALESCE(TRIM(username), '') <> ''
            """
        )
    else:

        print("users_username_unique skipped because duplicate usernames exist")

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS user_blocks (
            blocker_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            blocked_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW(),
            PRIMARY KEY (blocker_email, blocked_email),
            CHECK (blocker_email <> blocked_email)
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS reports (
            id SERIAL PRIMARY KEY,
            reporter_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            target_type TEXT NOT NULL,
            target_id TEXT NOT NULL,
            target_owner_email TEXT,
            reason TEXT NOT NULL,
            detail TEXT,
            created_at TIMESTAMP DEFAULT NOW(),
            status TEXT DEFAULT 'open'
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS email_verifications (
            email TEXT PRIMARY KEY,
            code TEXT NOT NULL,
            expires_at TIMESTAMP NOT NULL,
            verified_at TIMESTAMP
        )
        """
    )

    conn.commit()

    cur.close()
    conn.close()


def new_email_code() -> str:

    return f"{random.randint(100000, 999999)}"


def ensure_follows_table():

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS follows (
            follower_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            following_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW(),
            PRIMARY KEY (follower_email, following_email),
            CHECK (follower_email <> following_email)
        )
        """
    )

    conn.commit()

    cur.close()
    conn.close()


def ensure_groups_tables():

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS groups (
            id SERIAL PRIMARY KEY,
            name TEXT NOT NULL,
            owner_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )

    cur.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS groups_owner_name_unique
        ON groups (owner_email, name)
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS group_members (
            group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            user_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            joined_at TIMESTAMP DEFAULT NOW(),
            PRIMARY KEY (group_id, user_email)
        )
        """
    )

    conn.commit()

    cur.close()
    conn.close()


def ensure_dm_tables():

    ensure_groups_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_threads (
            id SERIAL PRIMARY KEY,
            user_one_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            user_two_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW(),
            CHECK (user_one_email <> user_two_email),
            UNIQUE (user_one_email, user_two_email)
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_messages (
            id SERIAL PRIMARY KEY,
            thread_id INTEGER NOT NULL REFERENCES dm_threads(id) ON DELETE CASCADE,
            sender_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            body TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_group_threads (
            id SERIAL PRIMARY KEY,
            group_id INTEGER NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW(),
            updated_at TIMESTAMP DEFAULT NOW(),
            UNIQUE (group_id)
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_group_messages (
            id SERIAL PRIMARY KEY,
            thread_id INTEGER NOT NULL REFERENCES dm_group_threads(id) ON DELETE CASCADE,
            sender_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            body TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_hidden_threads (
            thread_type TEXT NOT NULL,
            thread_id INTEGER NOT NULL,
            user_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            hidden_at TIMESTAMP DEFAULT NOW(),
            PRIMARY KEY (thread_type, thread_id, user_email)
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_thread_reads (
            thread_type TEXT NOT NULL,
            thread_id INTEGER NOT NULL,
            user_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            read_at TIMESTAMP DEFAULT NOW(),
            PRIMARY KEY (thread_type, thread_id, user_email)
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_polls (
            id SERIAL PRIMARY KEY,
            thread_type TEXT NOT NULL,
            thread_id INTEGER NOT NULL,
            message_id INTEGER NOT NULL,
            question TEXT NOT NULL,
            created_by TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_poll_options (
            id SERIAL PRIMARY KEY,
            poll_id INTEGER NOT NULL REFERENCES dm_polls(id) ON DELETE CASCADE,
            shop_key TEXT NOT NULL,
            shop_name TEXT NOT NULL,
            location TEXT NOT NULL,
            position INTEGER NOT NULL
        )
        """
    )

    cur.execute(
        """
        CREATE TABLE IF NOT EXISTS dm_poll_votes (
            poll_id INTEGER NOT NULL REFERENCES dm_polls(id) ON DELETE CASCADE,
            option_id INTEGER NOT NULL REFERENCES dm_poll_options(id) ON DELETE CASCADE,
            user_email TEXT NOT NULL REFERENCES users(email) ON DELETE CASCADE,
            created_at TIMESTAMP DEFAULT NOW(),
            PRIMARY KEY (option_id, user_email)
        )
        """
    )

    conn.commit()

    cur.close()
    conn.close()


def format_japanese_address(data: dict) -> str:

    address = data.get("address", {})

    prefectures = {
        "JP-01": "北海道",
        "JP-02": "青森県",
        "JP-03": "岩手県",
        "JP-04": "宮城県",
        "JP-05": "秋田県",
        "JP-06": "山形県",
        "JP-07": "福島県",
        "JP-08": "茨城県",
        "JP-09": "栃木県",
        "JP-10": "群馬県",
        "JP-11": "埼玉県",
        "JP-12": "千葉県",
        "JP-13": "東京都",
        "JP-14": "神奈川県",
        "JP-15": "新潟県",
        "JP-16": "富山県",
        "JP-17": "石川県",
        "JP-18": "福井県",
        "JP-19": "山梨県",
        "JP-20": "長野県",
        "JP-21": "岐阜県",
        "JP-22": "静岡県",
        "JP-23": "愛知県",
        "JP-24": "三重県",
        "JP-25": "滋賀県",
        "JP-26": "京都府",
        "JP-27": "大阪府",
        "JP-28": "兵庫県",
        "JP-29": "奈良県",
        "JP-30": "和歌山県",
        "JP-31": "鳥取県",
        "JP-32": "島根県",
        "JP-33": "岡山県",
        "JP-34": "広島県",
        "JP-35": "山口県",
        "JP-36": "徳島県",
        "JP-37": "香川県",
        "JP-38": "愛媛県",
        "JP-39": "高知県",
        "JP-40": "福岡県",
        "JP-41": "佐賀県",
        "JP-42": "長崎県",
        "JP-43": "熊本県",
        "JP-44": "大分県",
        "JP-45": "宮崎県",
        "JP-46": "鹿児島県",
        "JP-47": "沖縄県",
    }

    ordered_keys = [
        "province",
        "state",
        "county",
        "city",
        "town",
        "village",
        "city_district",
        "borough",
        "suburb",
        "neighbourhood",
        "quarter",
        "road",
        "pedestrian",
        "house_number",
        "building",
        "amenity",
        "shop",
    ]

    parts = []

    iso_prefecture = address.get("ISO3166-2-lvl4")

    if iso_prefecture in prefectures:

        parts.append(prefectures[iso_prefecture])

    for key in ordered_keys:

        value = address.get(key)

        if value and value not in parts:

            parts.append(value)

    if parts:

        return " ".join(parts)

    display_name = data.get("display_name", "")

    if display_name:

        display_parts = [
            part.strip()
            for part in display_name.split(",")
            if part.strip()
        ]

        display_parts = [
            part
            for part in display_parts
            if part != "日本" and not part.isdigit()
        ]

        return " ".join(reversed(display_parts))

    return ""


def reverse_geocode(latitude: float, longitude: float) -> str:

    params = urllib.parse.urlencode(
        {
            "format": "jsonv2",
            "lat": latitude,
            "lon": longitude,
            "accept-language": "ja",
            "zoom": 18,
            "addressdetails": 1
        }
    )

    request = urllib.request.Request(
        f"https://nominatim.openstreetmap.org/reverse?{params}",
        headers={
            "User-Agent": "FoodShare/1.0 kamiji1101@gmail.com"
        }
    )

    with urllib.request.urlopen(request, timeout=8) as response:

        data = json.loads(response.read().decode("utf-8"))

    return format_japanese_address(data)


def post_row_to_dict(row):

    return {
        "id": row[0],
        "user_email": row[1],
        "image_path": row[2],
        "shop_name": row[3] if row[3] else "店名未設定",
        "category": row[4],
        "price_range": row[5],
        "location": row[6],
        "comment": row[7],
        "tags": row[8] if row[8] else "",
        "latitude": row[9],
        "longitude": row[10],
        "created_at": row[11].isoformat() if row[11] else "",
        "username": row[12] if len(row) > 12 and row[12] else row[1],
    }

# =========================
# ⭐ プロフィール画像アップロード
# =========================
@app.post("/upload-profile-image")
async def upload_profile_image(

    email: str = Form(...),

    file: UploadFile = File(...)
):

    try:

        # ⭐ 保存先
        file_path = f"uploads/{file.filename}"

        # ⭐ uploads に保存
        with open(file_path, "wb") as buffer:

            shutil.copyfileobj(
                file.file,
                buffer
            )

        # ⭐ DB更新
        conn = psycopg2.connect(
            dbname="account_manage",
            user="ryohe1101",
            password="",
            host="localhost"
        )

        cur = conn.cursor()

        cur.execute(
            """
            UPDATE users
            SET profile_image = %s
            WHERE email = %s
            """,
            (
                file_path,
                email
            )
        )

        conn.commit()

        cur.close()
        conn.close()

        return {

            "message": "upload success",

            "file_path": file_path
        }

    except Exception as e:

        print("upload error")
        print(e)

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@app.post("/update-profile-image")
def update_profile_image(data: ProfileImageRequest):

    allowed_prefix = "uploads/characters/"
    profile_image = data.profile_image.strip()

    if not profile_image.startswith(allowed_prefix):

        raise HTTPException(
            status_code=400,
            detail="選択できない画像です"
        )

    image_path = BASE_DIR / profile_image

    if not image_path.exists():

        raise HTTPException(
            status_code=404,
            detail="画像が見つかりません"
        )

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        UPDATE users
        SET profile_image = %s
        WHERE email = %s
        RETURNING profile_image
        """,
        (
            profile_image,
            data.email
        )
    )

    row = cur.fetchone()

    conn.commit()

    cur.close()
    conn.close()

    if not row:

        raise HTTPException(
            status_code=404,
            detail="ユーザーが見つかりません"
        )

    return {
        "message": "profile image updated",
        "profile_image": row[0]
    }


# =========================
# ⭐ Login
# =========================
class LoginRequest(BaseModel):

    email: str
    password: str


class ProfileImageRequest(BaseModel):

    email: str
    profile_image: str


class FollowRequest(BaseModel):

    follower_email: str
    following_email: str


class CreateGroupRequest(BaseModel):

    owner_email: str
    name: str
    member_emails: list[str]


class AddGroupMembersRequest(BaseModel):

    member_emails: list[str]


class CreateDmThreadRequest(BaseModel):

    current_email: str
    target_email: str


class CreateGroupDmThreadRequest(BaseModel):

    current_email: str
    group_id: int


class SendDmMessageRequest(BaseModel):

    sender_email: str
    body: str


class CreateDmPollOptionRequest(BaseModel):

    shop_key: str
    shop_name: str
    location: str


class CreateDmPollRequest(BaseModel):

    sender_email: str
    options: list[CreateDmPollOptionRequest]


class VoteDmPollRequest(BaseModel):

    user_email: str
    option_ids: list[int]


class EmailRequest(BaseModel):

    email: str


class VerifyEmailRequest(BaseModel):

    email: str
    code: str


class ResetPasswordRequest(BaseModel):

    email: str
    code: str
    new_password: str


class DeleteAccountRequest(BaseModel):

    email: str
    password: str


class ReportRequest(BaseModel):

    reporter_email: str
    target_type: str
    target_id: str
    target_owner_email: Optional[str] = None
    reason: str
    detail: Optional[str] = ""


class BlockRequest(BaseModel):

    blocker_email: str
    blocked_email: str


@app.post("/login")
def login(data: LoginRequest):

    ensure_release_tables()

    conn = psycopg2.connect(
        dbname="account_manage",
        user="ryohe1101",
        password="",
        host="localhost"
    )

    cur = conn.cursor()

    cur.execute(
        """
        SELECT
            uuid,
            username,
            password_hash,
            role,
            birthday,
            email,
            profile_image
        FROM users
        WHERE email = %s
        """,
        (data.email,)
    )

    user = cur.fetchone()

    if not user:

        raise HTTPException(
            status_code=401,
            detail="ユーザー不存在"
        )

    # ⭐ index取得
    uuid_value = user[0]

    username = user[1]

    password_hash = user[2]

    role = user[3]

    birthday = user[4]

    email = user[5]

    profile_image = user[6]

    # ⭐ password check
    if data.password != password_hash:

        raise HTTPException(
            status_code=401,
            detail="パスワード不一致"
        )

    cur.close()
    conn.close()

    return {

        "message": "ログイン成功",

        "uuid": uuid_value,

        "username": username,

        "role": role,

        "birthday":
            str(birthday)
            if birthday else "",

        "email": email,

        "profile_image":
            profile_image
            if profile_image else "",
    }


# =========================
# ⭐ Register
# =========================
class User(BaseModel):

    email: str

    password: str

    username: str

    gender: str

    birthday: str

    profile_image: Optional[str] = ""


@app.post("/register")
def register(user: User):

    print(user)

    ensure_release_tables()

    try:

        conn = psycopg2.connect(
            dbname="account_manage",
            user="ryohe1101",
            password="",
            host="localhost"
        )

        cur = conn.cursor()

        print("INSERT前")

        normalized_username = user.username.strip()

        if not normalized_username:

            cur.close()
            conn.close()

            raise HTTPException(
                status_code=400,
                detail="ユーザー名を入力してください"
            )

        cur.execute(
            """
            SELECT 1
            FROM users
            WHERE LOWER(TRIM(username)) = LOWER(TRIM(%s))
            LIMIT 1
            """,
            (normalized_username,)
        )

        if cur.fetchone():

            cur.close()
            conn.close()

            raise HTTPException(
                status_code=409,
                detail="そのユーザー名は既に使われています"
            )

        cur.execute(
            """
            SELECT verified_at
            FROM email_verifications
            WHERE email = %s
            """,
            (user.email,)
        )

        verification_row = cur.fetchone()

        if not verification_row or not verification_row[0]:

            cur.close()
            conn.close()

            raise HTTPException(
                status_code=400,
                detail="メール認証を完了してください"
            )

        cur.execute(
            """
            INSERT INTO users (

                username,
                email,
                password_hash,
                created_at,
                is_active,
                role,
                uuid,
                sex,
                birthday,
                profile_image,
                is_email_verified,
                terms_accepted_at,
                privacy_accepted_at,
                location_consent_at

            )

            VALUES (
                %s,
                %s,
                %s,
                NOW(),
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                NOW(),
                NOW(),
                NOW()
            )
            """,
            (
                normalized_username,

                user.email,

                user.password,

                True,

                "user",

                str(uuid.uuid4()),

                user.gender,

                user.birthday,

                user.profile_image if user.profile_image else "",

                True
            )
        )

        conn.commit()

        print("INSERT成功")

        cur.close()

        conn.close()

        return {
            "status": "ok"
        }

    except Exception as e:

        if isinstance(e, HTTPException):

            raise e

        print("エラー内容↓↓↓↓↓↓↓↓")

        print(e)

        raise HTTPException(status_code=500, detail=str(e))


@app.post("/request-email-verification")
def request_email_verification(data: EmailRequest):

    ensure_release_tables()

    code = new_email_code()
    expires_at = datetime.now() + timedelta(minutes=15)

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO email_verifications (email, code, expires_at, verified_at)
        VALUES (%s, %s, %s, NULL)
        ON CONFLICT (email)
        DO UPDATE SET
            code = EXCLUDED.code,
            expires_at = EXCLUDED.expires_at,
            verified_at = NULL
        """,
        (data.email, code, expires_at)
    )

    conn.commit()
    cur.close()
    conn.close()

    print(f"email verification code for {data.email}: {code}")

    return {
        "status": "ok"
    }


@app.post("/verify-email")
def verify_email(data: VerifyEmailRequest):

    ensure_release_tables()

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT code, expires_at
        FROM email_verifications
        WHERE email = %s
        """,
        (data.email,)
    )

    row = cur.fetchone()

    if not row:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="認証コードを送信してください")

    code, expires_at = row

    if code != data.code or not expires_at or expires_at < datetime.now():
        cur.close()
        conn.close()
        raise HTTPException(status_code=400, detail="認証コードが違うか期限切れです")

    cur.execute(
        """
        UPDATE email_verifications
        SET verified_at = NOW()
        WHERE email = %s
        """,
        (data.email,)
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "ok"}


@app.post("/request-password-reset")
def request_password_reset(data: EmailRequest):

    ensure_release_tables()

    code = new_email_code()
    expires_at = datetime.now() + timedelta(minutes=15)

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        UPDATE users
        SET password_reset_code = %s,
            password_reset_expires_at = %s
        WHERE email = %s
        """,
        (code, expires_at, data.email)
    )

    if cur.rowcount == 0:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="メールアドレスが見つかりません")

    conn.commit()
    cur.close()
    conn.close()

    print(f"password reset code for {data.email}: {code}")

    return {
        "status": "ok"
    }


@app.post("/reset-password")
def reset_password(data: ResetPasswordRequest):

    ensure_release_tables()

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        SELECT password_reset_code, password_reset_expires_at
        FROM users
        WHERE email = %s
        """,
        (data.email,)
    )

    row = cur.fetchone()

    if not row:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="メールアドレスが見つかりません")

    code, expires_at = row

    if code != data.code or not expires_at or expires_at < datetime.now():
        cur.close()
        conn.close()
        raise HTTPException(status_code=400, detail="認証コードが違うか期限切れです")

    cur.execute(
        """
        UPDATE users
        SET password_hash = %s,
            password_reset_code = NULL,
            password_reset_expires_at = NULL
        WHERE email = %s
        """,
        (data.new_password, data.email)
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "ok"}

@app.post("/upload-post")
async def upload_post(

    user_email: str = Form(...),

    shop_name: str = Form(""),

    category: str = Form(...),

    price_range: str = Form(...),

    location: str = Form(...),

    comment: str = Form(...),

    tags: str = Form(""),

    latitude: Optional[float] = Form(None),

    longitude: Optional[float] = Form(None),

    file: UploadFile = File(...)
):

    try:

        ensure_posts_table()

        display_location = location.strip()

        if latitude is not None and longitude is not None:

            try:

                resolved_location = reverse_geocode(latitude, longitude)

                if resolved_location:

                    display_location = resolved_location

            except Exception as geocode_error:

                print("reverse geocode error")

                print(geocode_error)

        # ⭐ 保存先
        safe_filename = f"{uuid.uuid4()}_{file.filename}"

        file_path = f"Posts/{safe_filename}"

        # ⭐ Posts folder に保存
        with open(POSTS_DIR / safe_filename, "wb") as buffer:

            shutil.copyfileobj(
                file.file,
                buffer
            )

        # ⭐ DB接続
        conn = get_db_connection()

        cur = conn.cursor()

        # ⭐ posts table INSERT
        cur.execute(
            """
            INSERT INTO posts (

                user_email,
                image_path,
                shop_name,
                category,
                price_range,
                location,
                comment,
                tags,
                latitude,
                longitude

            )

            VALUES (
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s,
                %s
            )
            """,
            (
                user_email,
                file_path,
                shop_name.strip() if shop_name.strip() else "店名未設定",
                category,
                price_range,
                display_location,
                comment,
                tags,
                latitude,
                longitude
            )
        )

        conn.commit()

        cur.close()

        conn.close()

        return {

            "message": "post success",

            "image_path": file_path,

            "location": display_location
        }

    except Exception as e:

        print("post upload error")

        print(e)

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@app.get("/reverse-geocode")
def reverse_geocode_endpoint(
    latitude: float,
    longitude: float
):

    try:

        address = reverse_geocode(latitude, longitude)

        return {
            "address": address
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )


@app.get("/posts")
def get_posts(
    user_email: Optional[str] = None,
    following_email: Optional[str] = None,
    viewer_email: Optional[str] = None,
    location: Optional[str] = None,
    price_range: Optional[str] = None,
    category: Optional[str] = None,
    tag: Optional[str] = None,
    limit: int = 50
):

    ensure_posts_table()
    ensure_release_tables()

    if following_email:

        ensure_follows_table()

    conn = get_db_connection()

    cur = conn.cursor()

    conditions = []

    params = []

    if user_email:

        conditions.append("p.user_email = %s")

        params.append(user_email)

    if following_email:

        conditions.append(
            """
            EXISTS (
                SELECT 1
                FROM follows f
                WHERE f.follower_email = %s
                  AND f.following_email = p.user_email
            )
            """
        )

        params.append(following_email)

    if viewer_email:

        conditions.append(
            """
            NOT EXISTS (
                SELECT 1
                FROM user_blocks b
                WHERE b.blocker_email = %s
                  AND b.blocked_email = p.user_email
            )
            """
        )

        params.append(viewer_email)

    if location:

        conditions.append("p.location ILIKE %s")

        params.append(f"%{location}%")

    if price_range:

        conditions.append("p.price_range = %s")

        params.append(price_range)

    if category:

        if " / " in category:

            legacy_child_category = category.split(" / ")[-1]

            conditions.append("(p.category = %s OR p.category = %s)")

            params.extend([category, legacy_child_category])

        else:

            legacy_categories = {
                "カフェ・スイーツ": ["スイーツ"],
                "バー・ダイニングバー": ["ドリンク"],
            }.get(category, [])

            legacy_placeholders = "".join(" OR p.category = %s" for _ in legacy_categories)

            conditions.append(f"(p.category = %s OR p.category LIKE %s{legacy_placeholders})")

            params.extend([category, f"{category} / %", *legacy_categories])

    if tag:

        conditions.append("p.tags ILIKE %s")

        params.append(f"%{tag}%")

    where_clause = ""

    if conditions:

        where_clause = "WHERE " + " AND ".join(conditions)

    params.append(limit)

    cur.execute(
        f"""
        SELECT
            p.id,
            p.user_email,
            p.image_path,
            p.shop_name,
            p.category,
            p.price_range,
            p.location,
            p.comment,
            p.tags,
            p.latitude,
            p.longitude,
            p.created_at,
            u.username
        FROM posts p
        LEFT JOIN users u ON u.email = p.user_email
        {where_clause}
        ORDER BY p.created_at DESC, p.id DESC
        LIMIT %s
        """,
        tuple(params)
    )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "posts": [
            post_row_to_dict(row)
            for row in rows
        ]
    }


@app.delete("/posts/{post_id}")
def delete_post(post_id: int, user_email: str):

    ensure_posts_table()

    conn = get_db_connection()
    cur = conn.cursor()

    cur.execute(
        "DELETE FROM posts WHERE id = %s AND user_email = %s RETURNING image_path",
        (post_id, user_email)
    )

    row = cur.fetchone()

    if not row:
        cur.close()
        conn.close()
        raise HTTPException(status_code=404, detail="削除できる投稿が見つかりません")

    conn.commit()
    cur.close()
    conn.close()

    image_path = row[0]
    if image_path:
        local_path = BASE_DIR / image_path
        if local_path.exists() and local_path.is_file():
            local_path.unlink()

    return {"status": "ok"}


@app.post("/reports")
def create_report(data: ReportRequest):

    ensure_release_tables()

    if not data.reason.strip():
        raise HTTPException(status_code=400, detail="通報理由を入力してください")

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO reports (
            reporter_email,
            target_type,
            target_id,
            target_owner_email,
            reason,
            detail
        )
        VALUES (%s, %s, %s, %s, %s, %s)
        """,
        (
            data.reporter_email,
            data.target_type,
            data.target_id,
            data.target_owner_email,
            data.reason,
            data.detail or "",
        )
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "ok"}


@app.post("/block")
def block_user(data: BlockRequest):

    ensure_release_tables()

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO user_blocks (blocker_email, blocked_email)
        VALUES (%s, %s)
        ON CONFLICT DO NOTHING
        """,
        (data.blocker_email, data.blocked_email)
    )

    cur.execute(
        "DELETE FROM follows WHERE follower_email = %s AND following_email = %s",
        (data.blocker_email, data.blocked_email)
    )
    cur.execute(
        "DELETE FROM follows WHERE follower_email = %s AND following_email = %s",
        (data.blocked_email, data.blocker_email)
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "ok"}


@app.delete("/account")
def delete_account(data: DeleteAccountRequest):

    ensure_release_tables()

    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "SELECT password_hash FROM users WHERE email = %s",
        (data.email,)
    )

    row = cur.fetchone()

    if not row or row[0] != data.password:
        cur.close()
        conn.close()
        raise HTTPException(status_code=401, detail="パスワードが違います")

    cur.execute(
        "DELETE FROM users WHERE email = %s",
        (data.email,)
    )

    conn.commit()
    cur.close()
    conn.close()

    return {"status": "ok"}


@app.post("/delete-account")
def delete_account_post(data: DeleteAccountRequest):

    return delete_account(data)


@app.get("/users")
def get_users(
    exclude_email: Optional[str] = None,
    viewer_email: Optional[str] = None,
    query: Optional[str] = None,
    limit: int = 100
):

    ensure_follows_table()
    ensure_release_tables()

    search_query = query.strip() if query else ""
    safe_limit = max(1, min(limit, 100))

    conn = get_db_connection()

    cur = conn.cursor()

    conditions = []

    params = [viewer_email if viewer_email else ""]

    if exclude_email:

        conditions.append("u.email <> %s")

        params.append(exclude_email)

    if search_query:

        conditions.append("COALESCE(u.username, '') ILIKE %s")

        params.append(f"%{search_query}%")

    if viewer_email:

        conditions.append(
            """
            NOT EXISTS (
                SELECT 1
                FROM user_blocks b
                WHERE (b.blocker_email = %s AND b.blocked_email = u.email)
                   OR (b.blocker_email = u.email AND b.blocked_email = %s)
            )
            """
        )

        params.extend([viewer_email, viewer_email])

    where_clause = ""

    if conditions:

        where_clause = "WHERE " + " AND ".join(conditions)

    params.append(safe_limit)

    cur.execute(
        f"""
        SELECT
            u.username,
            u.email,
            u.profile_image,
            EXISTS (
                SELECT 1
                FROM follows f
                WHERE f.follower_email = %s
                  AND f.following_email = u.email
            ) AS is_following
        FROM users u
        {where_clause}
        ORDER BY LOWER(COALESCE(NULLIF(u.username, ''), u.email)) ASC
        LIMIT %s
        """,
        tuple(params)
    )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "users": [
            {
                "username": row[0],
                "email": row[1],
                "profile_image": row[2] if row[2] else "",
                "is_following": row[3],
            }
            for row in rows
        ]
    }


@app.get("/follow-stats")
def get_follow_stats(email: str):

    ensure_follows_table()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        "SELECT COUNT(*) FROM follows WHERE following_email = %s",
        (
            email,
        )
    )

    followers_count = cur.fetchone()[0]

    cur.execute(
        "SELECT COUNT(*) FROM follows WHERE follower_email = %s",
        (
            email,
        )
    )

    following_count = cur.fetchone()[0]

    cur.close()
    conn.close()

    return {
        "followers_count": followers_count,
        "following_count": following_count
    }


@app.get("/follow-list")
def get_follow_list(
    email: str,
    list_type: str,
    viewer_email: Optional[str] = None
):

    ensure_follows_table()

    conn = get_db_connection()

    cur = conn.cursor()

    if list_type == "followers":

        cur.execute(
            """
            SELECT
                u.username,
                u.email,
                u.profile_image,
                EXISTS (
                    SELECT 1
                    FROM follows vf
                    WHERE vf.follower_email = %s
                      AND vf.following_email = u.email
                ) AS is_following
            FROM follows f
            JOIN users u ON u.email = f.follower_email
            WHERE f.following_email = %s
            ORDER BY f.created_at DESC
            """,
            (
                viewer_email if viewer_email else "",
                email,
            )
        )

    elif list_type == "following":

        cur.execute(
            """
            SELECT
                u.username,
                u.email,
                u.profile_image,
                EXISTS (
                    SELECT 1
                    FROM follows vf
                    WHERE vf.follower_email = %s
                      AND vf.following_email = u.email
                ) AS is_following
            FROM follows f
            JOIN users u ON u.email = f.following_email
            WHERE f.follower_email = %s
            ORDER BY f.created_at DESC
            """,
            (
                viewer_email if viewer_email else "",
                email,
            )
        )

    else:

        raise HTTPException(
            status_code=400,
            detail="list_type must be followers or following"
        )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "users": [
            {
                "username": row[0],
                "email": row[1],
                "profile_image": row[2] if row[2] else "",
                "is_following": row[3],
            }
            for row in rows
        ]
    }


@app.get("/dm/search-users")
def search_dm_users(
    email: str,
    query: str = "",
    limit: int = 20
):

    ensure_follows_table()
    ensure_groups_tables()

    search_query = query.strip()
    safe_limit = max(1, min(limit, 50))

    conn = get_db_connection()

    cur = conn.cursor()

    params = [
        email,
        email,
    ]

    query_clause = ""

    if search_query:

        query_clause = "AND COALESCE(u.username, '') ILIKE %s"

        params.append(f"%{search_query}%")

    params.append(safe_limit)

    cur.execute(
        f"""
        SELECT
            u.username,
            u.email,
            u.profile_image,
            TRUE AS is_following
        FROM follows f
        JOIN users u ON u.email = f.following_email
        WHERE f.follower_email = %s
          AND u.email <> %s
          {query_clause}
        ORDER BY f.created_at DESC, LOWER(COALESCE(NULLIF(u.username, ''), u.email)) ASC
        LIMIT %s
        """,
        tuple(params)
    )

    rows = cur.fetchall()

    group_params = [
        email,
    ]

    group_query_clause = ""

    if search_query:

        group_query_clause = "AND g.name ILIKE %s"

        group_params.append(f"%{search_query}%")

    group_params.append(safe_limit)

    cur.execute(
        f"""
        SELECT
            g.id,
            g.name,
            g.owner_email,
            g.created_at,
            COUNT(gm_all.user_email) AS member_count
        FROM groups g
        JOIN group_members gm_me
          ON gm_me.group_id = g.id
         AND gm_me.user_email = %s
        LEFT JOIN group_members gm_all
          ON gm_all.group_id = g.id
        WHERE 1 = 1
          {group_query_clause}
        GROUP BY g.id, g.name, g.owner_email, g.created_at
        ORDER BY g.created_at DESC, g.id DESC
        LIMIT %s
        """,
        tuple(group_params)
    )

    group_rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "users": [
            {
                "username": row[0],
                "email": row[1],
                "profile_image": row[2] if row[2] else "",
                "is_following": row[3],
            }
            for row in rows
        ],
        "groups": [
            {
                "id": row[0],
                "name": row[1],
                "owner_email": row[2],
                "created_at": row[3].isoformat() if row[3] else "",
                "member_count": row[4],
            }
            for row in group_rows
        ],
    }


@app.get("/dm/threads")
def get_dm_threads(email: str):

    ensure_dm_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        SELECT
            t.id,
            t.updated_at,
            other_user.username,
            other_user.email,
            other_user.profile_image,
            last_message.body,
            last_message.created_at,
            COALESCE(unread.unread_count, 0) AS unread_count
        FROM dm_threads t
        JOIN users other_user
          ON other_user.email = CASE
              WHEN t.user_one_email = %s THEN t.user_two_email
              ELSE t.user_one_email
          END
        LEFT JOIN LATERAL (
            SELECT body, created_at
            FROM dm_messages m
            WHERE m.thread_id = t.id
            ORDER BY m.created_at DESC, m.id DESC
            LIMIT 1
        ) last_message ON TRUE
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS unread_count
            FROM dm_messages m
            LEFT JOIN dm_thread_reads r
              ON r.thread_type = 'direct'
             AND r.thread_id = t.id
             AND r.user_email = %s
            WHERE m.thread_id = t.id
              AND m.sender_email <> %s
              AND (
                  r.read_at IS NULL
                  OR m.created_at > r.read_at
              )
        ) unread ON TRUE
        WHERE (t.user_one_email = %s OR t.user_two_email = %s)
          AND NOT EXISTS (
              SELECT 1
              FROM dm_hidden_threads h
              WHERE h.thread_type = 'direct'
                AND h.thread_id = t.id
                AND h.user_email = %s
          )
        ORDER BY COALESCE(last_message.created_at, t.updated_at) DESC, t.id DESC
        """,
        (
            email,
            email,
            email,
            email,
            email,
            email,
        )
    )

    rows = cur.fetchall()

    cur.execute(
        """
        SELECT
            gt.id,
            gt.updated_at,
            g.id,
            g.name,
            COUNT(gm_all.user_email) AS member_count,
            last_message.body,
            last_message.created_at,
            COALESCE(unread.unread_count, 0) AS unread_count
        FROM dm_group_threads gt
        JOIN groups g ON g.id = gt.group_id
        JOIN group_members gm_me
          ON gm_me.group_id = g.id
         AND gm_me.user_email = %s
        LEFT JOIN group_members gm_all
          ON gm_all.group_id = g.id
        LEFT JOIN LATERAL (
            SELECT body, created_at
            FROM dm_group_messages m
            WHERE m.thread_id = gt.id
            ORDER BY m.created_at DESC, m.id DESC
            LIMIT 1
        ) last_message ON TRUE
        LEFT JOIN LATERAL (
            SELECT COUNT(*) AS unread_count
            FROM dm_group_messages m
            LEFT JOIN dm_thread_reads r
              ON r.thread_type = 'group'
             AND r.thread_id = gt.id
             AND r.user_email = %s
            WHERE m.thread_id = gt.id
              AND m.sender_email <> %s
              AND (
                  r.read_at IS NULL
                  OR m.created_at > r.read_at
              )
        ) unread ON TRUE
        WHERE NOT EXISTS (
            SELECT 1
            FROM dm_hidden_threads h
            WHERE h.thread_type = 'group'
              AND h.thread_id = gt.id
              AND h.user_email = %s
        )
        GROUP BY gt.id, gt.updated_at, g.id, g.name, last_message.body, last_message.created_at, unread.unread_count
        ORDER BY COALESCE(last_message.created_at, gt.updated_at) DESC, gt.id DESC
        """,
        (
            email,
            email,
            email,
            email,
        )
    )

    group_rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "threads": sorted([
            {
                "id": row[0],
                "thread_type": "direct",
                "updated_at": row[1].isoformat() if row[1] else "",
                "other_user": {
                    "username": row[2],
                    "email": row[3],
                    "profile_image": row[4] if row[4] else "",
                    "is_following": True,
                },
                "last_message": row[5] if row[5] else "",
                "last_message_at": row[6].isoformat() if row[6] else "",
                "unread_count": row[7],
            }
            for row in rows
        ] + [
            {
                "id": row[0],
                "thread_type": "group",
                "updated_at": row[1].isoformat() if row[1] else "",
                "group": {
                    "id": row[2],
                    "name": row[3],
                    "member_count": row[4],
                },
                "last_message": row[5] if row[5] else "",
                "last_message_at": row[6].isoformat() if row[6] else "",
                "unread_count": row[7],
            }
            for row in group_rows
        ], key=lambda thread: thread["last_message_at"] or thread["updated_at"], reverse=True)
    }


@app.get("/dm/unread-count")
def get_dm_unread_count(email: str):

    ensure_dm_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        SELECT COUNT(*)
        FROM dm_threads t
        JOIN dm_messages m ON m.thread_id = t.id
        LEFT JOIN dm_thread_reads r
          ON r.thread_type = 'direct'
         AND r.thread_id = t.id
         AND r.user_email = %s
        WHERE (t.user_one_email = %s OR t.user_two_email = %s)
          AND m.sender_email <> %s
          AND (
              r.read_at IS NULL
              OR m.created_at > r.read_at
          )
          AND NOT EXISTS (
              SELECT 1
              FROM dm_hidden_threads h
              WHERE h.thread_type = 'direct'
                AND h.thread_id = t.id
                AND h.user_email = %s
          )
        """,
        (
            email,
            email,
            email,
            email,
            email,
        )
    )

    direct_count = cur.fetchone()[0]

    cur.execute(
        """
        SELECT COUNT(*)
        FROM dm_group_threads gt
        JOIN group_members gm ON gm.group_id = gt.group_id
        JOIN dm_group_messages m ON m.thread_id = gt.id
        LEFT JOIN dm_thread_reads r
          ON r.thread_type = 'group'
         AND r.thread_id = gt.id
         AND r.user_email = %s
        WHERE gm.user_email = %s
          AND m.sender_email <> %s
          AND (
              r.read_at IS NULL
              OR m.created_at > r.read_at
          )
          AND NOT EXISTS (
              SELECT 1
              FROM dm_hidden_threads h
              WHERE h.thread_type = 'group'
                AND h.thread_id = gt.id
                AND h.user_email = %s
          )
        """,
        (
            email,
            email,
            email,
            email,
        )
    )

    group_count = cur.fetchone()[0]

    cur.close()
    conn.close()

    return {
        "unread_count": direct_count + group_count
    }


@app.post("/dm/threads")
def create_dm_thread(data: CreateDmThreadRequest):

    ensure_follows_table()
    ensure_dm_tables()

    if data.current_email == data.target_email:

        raise HTTPException(
            status_code=400,
            detail="自分にはDMを送れません"
        )

    user_one_email, user_two_email = sorted([
        data.current_email,
        data.target_email,
    ])

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        cur.execute(
            """
            SELECT 1
            FROM follows
            WHERE follower_email = %s
              AND following_email = %s
            """,
            (
                data.current_email,
                data.target_email,
            )
        )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=403,
                detail="フォロー中のアカウントにだけDMできます"
            )

        cur.execute(
            """
            INSERT INTO dm_threads (user_one_email, user_two_email)
            VALUES (%s, %s)
            ON CONFLICT (user_one_email, user_two_email)
            DO UPDATE SET updated_at = dm_threads.updated_at
            RETURNING id, updated_at
            """,
            (
                user_one_email,
                user_two_email,
            )
        )

        thread_id, updated_at = cur.fetchone()

        cur.execute(
            """
            DELETE FROM dm_hidden_threads
            WHERE thread_type = 'direct'
              AND thread_id = %s
              AND user_email = %s
            """,
            (
                thread_id,
                data.current_email,
            )
        )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "id": thread_id,
        "updated_at": updated_at.isoformat() if updated_at else "",
    }


@app.post("/dm/group-threads")
def create_group_dm_thread(data: CreateGroupDmThreadRequest):

    ensure_dm_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        cur.execute(
            """
            SELECT 1
            FROM group_members
            WHERE group_id = %s
              AND user_email = %s
            """,
            (
                data.group_id,
                data.current_email,
            )
        )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=403,
                detail="所属しているグループにだけDMできます"
            )

        cur.execute(
            """
            INSERT INTO dm_group_threads (group_id)
            VALUES (%s)
            ON CONFLICT (group_id)
            DO UPDATE SET updated_at = dm_group_threads.updated_at
            RETURNING id, updated_at
            """,
            (
                data.group_id,
            )
        )

        thread_id, updated_at = cur.fetchone()

        cur.execute(
            """
            DELETE FROM dm_hidden_threads
            WHERE thread_type = 'group'
              AND thread_id = %s
              AND user_email = %s
            """,
            (
                thread_id,
                data.current_email,
            )
        )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "id": thread_id,
        "thread_type": "group",
        "updated_at": updated_at.isoformat() if updated_at else "",
    }


@app.delete("/dm/threads/{thread_id}")
def delete_dm_thread(
    thread_id: int,
    email: str,
    thread_type: str = "direct"
):

    ensure_dm_tables()

    if thread_type not in ["direct", "group"]:

        raise HTTPException(
            status_code=400,
            detail="thread_type must be direct or group"
        )

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        if thread_type == "direct":

            cur.execute(
                """
                SELECT 1
                FROM dm_threads
                WHERE id = %s
                  AND (user_one_email = %s OR user_two_email = %s)
                """,
                (
                    thread_id,
                    email,
                    email,
                )
            )

        else:

            cur.execute(
                """
                SELECT 1
                FROM dm_group_threads gt
                JOIN group_members gm ON gm.group_id = gt.group_id
                WHERE gt.id = %s
                  AND gm.user_email = %s
                """,
                (
                    thread_id,
                    email,
                )
            )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=404,
                detail="thread not found"
            )

        cur.execute(
            """
            INSERT INTO dm_hidden_threads (thread_type, thread_id, user_email)
            VALUES (%s, %s, %s)
            ON CONFLICT (thread_type, thread_id, user_email)
            DO UPDATE SET hidden_at = NOW()
            """,
            (
                thread_type,
                thread_id,
                email,
            )
        )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "status": "ok"
    }


@app.get("/dm/threads/{thread_id}/messages")
def get_dm_messages(
    thread_id: int,
    email: str,
    thread_type: str = "direct"
):

    ensure_dm_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    if thread_type == "direct":

        cur.execute(
            """
            SELECT 1
            FROM dm_threads
            WHERE id = %s
              AND (user_one_email = %s OR user_two_email = %s)
            """,
            (
                thread_id,
                email,
                email,
            )
        )

    elif thread_type == "group":

        cur.execute(
            """
            SELECT 1
            FROM dm_group_threads gt
            JOIN group_members gm ON gm.group_id = gt.group_id
            WHERE gt.id = %s
              AND gm.user_email = %s
            """,
            (
                thread_id,
                email,
            )
        )

    else:

        cur.close()
        conn.close()

        raise HTTPException(
            status_code=400,
            detail="thread_type must be direct or group"
        )

    if cur.fetchone() is None:

        cur.close()
        conn.close()

        raise HTTPException(
            status_code=404,
            detail="thread not found"
        )

    message_table = "dm_group_messages" if thread_type == "group" else "dm_messages"

    cur.execute(
        f"""
        SELECT
            id,
            sender_email,
            body,
            created_at
        FROM {message_table}
        WHERE thread_id = %s
        ORDER BY created_at ASC, id ASC
        """,
        (
            thread_id,
        )
    )

    rows = cur.fetchall()

    message_ids = [row[0] for row in rows]
    polls_by_message_id = {}

    if message_ids:

        cur.execute(
            """
            SELECT
                p.id,
                p.message_id,
                p.question,
                p.created_by,
                p.created_at,
                o.id,
                o.shop_key,
                o.shop_name,
                o.location,
                o.position,
                COUNT(v.user_email) AS vote_count,
                EXISTS (
                    SELECT 1
                    FROM dm_poll_votes my_vote
                    WHERE my_vote.option_id = o.id
                      AND my_vote.user_email = %s
                ) AS voted_by_me
            FROM dm_polls p
            JOIN dm_poll_options o ON o.poll_id = p.id
            LEFT JOIN dm_poll_votes v ON v.option_id = o.id
            WHERE p.thread_type = %s
              AND p.thread_id = %s
              AND p.message_id = ANY(%s)
            GROUP BY p.id, p.message_id, p.question, p.created_by, p.created_at,
                     o.id, o.shop_key, o.shop_name, o.location, o.position
            ORDER BY p.id ASC, o.position ASC
            """,
            (
                email,
                thread_type,
                thread_id,
                message_ids,
            )
        )

        poll_rows = cur.fetchall()

        for poll_row in poll_rows:

            poll = polls_by_message_id.setdefault(
                poll_row[1],
                {
                    "id": poll_row[0],
                    "question": poll_row[2],
                    "created_by": poll_row[3],
                    "created_at": poll_row[4].isoformat() if poll_row[4] else "",
                    "options": [],
                }
            )

            poll["options"].append(
                {
                    "id": poll_row[5],
                    "shop_key": poll_row[6],
                    "shop_name": poll_row[7],
                    "location": poll_row[8],
                    "position": poll_row[9],
                    "vote_count": poll_row[10],
                    "voted_by_me": poll_row[11],
                }
            )

    cur.execute(
        """
        INSERT INTO dm_thread_reads (thread_type, thread_id, user_email, read_at)
        VALUES (%s, %s, %s, NOW())
        ON CONFLICT (thread_type, thread_id, user_email)
        DO UPDATE SET read_at = NOW()
        """,
        (
            thread_type,
            thread_id,
            email,
        )
    )

    conn.commit()

    cur.close()
    conn.close()

    return {
        "messages": [
            {
                "id": row[0],
                "sender_email": row[1],
                "body": row[2],
                "created_at": row[3].isoformat() if row[3] else "",
                "poll": polls_by_message_id.get(row[0]),
            }
            for row in rows
        ]
    }


@app.post("/dm/threads/{thread_id}/messages")
def send_dm_message(
    thread_id: int,
    data: SendDmMessageRequest,
    thread_type: str = "direct"
):

    ensure_dm_tables()

    body = data.body.strip()

    if not body:

        raise HTTPException(
            status_code=400,
            detail="メッセージを入力してください"
        )

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        if thread_type == "direct":

            cur.execute(
                """
                SELECT 1
                FROM dm_threads
                WHERE id = %s
                  AND (user_one_email = %s OR user_two_email = %s)
                """,
                (
                    thread_id,
                    data.sender_email,
                    data.sender_email,
                )
            )

            message_table = "dm_messages"
            thread_table = "dm_threads"

        elif thread_type == "group":

            cur.execute(
                """
                SELECT 1
                FROM dm_group_threads gt
                JOIN group_members gm ON gm.group_id = gt.group_id
                WHERE gt.id = %s
                  AND gm.user_email = %s
                """,
                (
                    thread_id,
                    data.sender_email,
                )
            )

            message_table = "dm_group_messages"
            thread_table = "dm_group_threads"

        else:

            raise HTTPException(
                status_code=400,
                detail="thread_type must be direct or group"
            )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=404,
                detail="thread not found"
            )

        cur.execute(
            f"""
            INSERT INTO {message_table} (thread_id, sender_email, body)
            VALUES (%s, %s, %s)
            RETURNING id, created_at
            """,
            (
                thread_id,
                data.sender_email,
                body,
            )
        )

        message_id, created_at = cur.fetchone()

        cur.execute(
            f"""
            UPDATE {thread_table}
            SET updated_at = NOW()
            WHERE id = %s
            """,
            (
                thread_id,
            )
        )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "id": message_id,
        "sender_email": data.sender_email,
        "body": body,
        "created_at": created_at.isoformat() if created_at else "",
    }


@app.post("/dm/threads/{thread_id}/polls")
def create_dm_poll(
    thread_id: int,
    data: CreateDmPollRequest,
    thread_type: str = "direct"
):

    ensure_dm_tables()

    poll_options = [
        option
        for option in data.options
        if option.shop_name.strip()
    ]

    if len(poll_options) < 2:

        raise HTTPException(
            status_code=400,
            detail="アンケート候補は2つ以上選択してください"
        )

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        if thread_type == "direct":

            cur.execute(
                """
                SELECT 1
                FROM dm_threads
                WHERE id = %s
                  AND (user_one_email = %s OR user_two_email = %s)
                """,
                (
                    thread_id,
                    data.sender_email,
                    data.sender_email,
                )
            )

            message_table = "dm_messages"
            thread_table = "dm_threads"

        elif thread_type == "group":

            cur.execute(
                """
                SELECT 1
                FROM dm_group_threads gt
                JOIN group_members gm ON gm.group_id = gt.group_id
                WHERE gt.id = %s
                  AND gm.user_email = %s
                """,
                (
                    thread_id,
                    data.sender_email,
                )
            )

            message_table = "dm_group_messages"
            thread_table = "dm_group_threads"

        else:

            raise HTTPException(
                status_code=400,
                detail="thread_type must be direct or group"
            )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=404,
                detail="thread not found"
            )

        body = "[アンケート] 行きたい店舗を選んでください"

        cur.execute(
            f"""
            INSERT INTO {message_table} (thread_id, sender_email, body)
            VALUES (%s, %s, %s)
            RETURNING id, created_at
            """,
            (
                thread_id,
                data.sender_email,
                body,
            )
        )

        message_id, created_at = cur.fetchone()

        cur.execute(
            """
            INSERT INTO dm_polls (
                thread_type,
                thread_id,
                message_id,
                question,
                created_by
            )
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
            """,
            (
                thread_type,
                thread_id,
                message_id,
                "行きたい店舗を選んでください",
                data.sender_email,
            )
        )

        poll_id = cur.fetchone()[0]

        for index, option in enumerate(poll_options):

            cur.execute(
                """
                INSERT INTO dm_poll_options (
                    poll_id,
                    shop_key,
                    shop_name,
                    location,
                    position
                )
                VALUES (%s, %s, %s, %s, %s)
                """,
                (
                    poll_id,
                    option.shop_key.strip(),
                    option.shop_name.strip(),
                    option.location.strip(),
                    index,
                )
            )

        cur.execute(
            f"""
            UPDATE {thread_table}
            SET updated_at = NOW()
            WHERE id = %s
            """,
            (
                thread_id,
            )
        )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "id": message_id,
        "sender_email": data.sender_email,
        "body": body,
        "created_at": created_at.isoformat() if created_at else "",
        "poll_id": poll_id,
    }


@app.post("/dm/polls/{poll_id}/vote")
def vote_dm_poll(
    poll_id: int,
    data: VoteDmPollRequest
):

    ensure_dm_tables()

    option_ids = sorted(set(data.option_ids))

    if not option_ids:

        raise HTTPException(
            status_code=400,
            detail="回答を選択してください"
        )

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        cur.execute(
            """
            SELECT thread_type, thread_id
            FROM dm_polls
            WHERE id = %s
            """,
            (
                poll_id,
            )
        )

        poll_row = cur.fetchone()

        if poll_row is None:

            raise HTTPException(
                status_code=404,
                detail="poll not found"
            )

        thread_type, thread_id = poll_row

        if thread_type == "direct":

            cur.execute(
                """
                SELECT 1
                FROM dm_threads
                WHERE id = %s
                  AND (user_one_email = %s OR user_two_email = %s)
                """,
                (
                    thread_id,
                    data.user_email,
                    data.user_email,
                )
            )

        else:

            cur.execute(
                """
                SELECT 1
                FROM dm_group_threads gt
                JOIN group_members gm ON gm.group_id = gt.group_id
                WHERE gt.id = %s
                  AND gm.user_email = %s
                """,
                (
                    thread_id,
                    data.user_email,
                )
            )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=403,
                detail="poll not available"
            )

        cur.execute(
            """
            SELECT id
            FROM dm_poll_options
            WHERE poll_id = %s
              AND id = ANY(%s)
            """,
            (
                poll_id,
                option_ids,
            )
        )

        valid_option_ids = [row[0] for row in cur.fetchall()]

        if len(valid_option_ids) != len(option_ids):

            raise HTTPException(
                status_code=400,
                detail="invalid option"
            )

        cur.execute(
            """
            DELETE FROM dm_poll_votes
            WHERE poll_id = %s
              AND user_email = %s
            """,
            (
                poll_id,
                data.user_email,
            )
        )

        for option_id in valid_option_ids:

            cur.execute(
                """
                INSERT INTO dm_poll_votes (poll_id, option_id, user_email)
                VALUES (%s, %s, %s)
                """,
                (
                    poll_id,
                    option_id,
                    data.user_email,
                )
            )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "status": "ok"
    }


@app.get("/group-stats")
def get_group_stats(email: str):

    ensure_groups_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        SELECT COUNT(*)
        FROM group_members
        WHERE user_email = %s
        """,
        (
            email,
        )
    )

    groups_count = cur.fetchone()[0]

    cur.close()
    conn.close()

    return {
        "groups_count": groups_count
    }


@app.get("/groups")
def get_groups(email: str):

    ensure_groups_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        SELECT
            g.id,
            g.name,
            g.owner_email,
            g.created_at,
            COUNT(gm_all.user_email) AS member_count
        FROM groups g
        JOIN group_members gm_me
          ON gm_me.group_id = g.id
         AND gm_me.user_email = %s
        LEFT JOIN group_members gm_all
          ON gm_all.group_id = g.id
        GROUP BY g.id, g.name, g.owner_email, g.created_at
        ORDER BY g.created_at DESC, g.id DESC
        """,
        (
            email,
        )
    )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "groups": [
            {
                "id": row[0],
                "name": row[1],
                "owner_email": row[2],
                "created_at": row[3].isoformat() if row[3] else "",
                "member_count": row[4],
            }
            for row in rows
        ]
    }


@app.post("/groups")
def create_group(data: CreateGroupRequest):

    ensure_groups_tables()

    group_name = data.name.strip()

    if not group_name:

        raise HTTPException(
            status_code=400,
            detail="group name is required"
        )

    member_emails = {
        email.strip()
        for email in data.member_emails
        if email.strip()
    }

    member_emails.add(data.owner_email)

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        cur.execute(
            """
            SELECT 1
            FROM groups
            WHERE owner_email = %s
              AND name = %s
            """,
            (
                data.owner_email,
                group_name,
            )
        )

        if cur.fetchone() is not None:

            raise HTTPException(
                status_code=409,
                detail="既にその名前を使用しています"
            )

        cur.execute(
            """
            INSERT INTO groups (name, owner_email)
            VALUES (%s, %s)
            RETURNING id, created_at
            """,
            (
                group_name,
                data.owner_email,
            )
        )

        group_id, created_at = cur.fetchone()

        for member_email in member_emails:

            cur.execute(
                """
                INSERT INTO group_members (group_id, user_email)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING
                """,
                (
                    group_id,
                    member_email,
                )
            )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "id": group_id,
        "name": group_name,
        "owner_email": data.owner_email,
        "created_at": created_at.isoformat() if created_at else "",
        "member_count": len(member_emails),
    }


@app.get("/groups/{group_id}/members")
def get_group_members(
    group_id: int,
    viewer_email: Optional[str] = None
):

    ensure_groups_tables()
    ensure_follows_table()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        SELECT
            u.username,
            u.email,
            u.profile_image,
            EXISTS (
                SELECT 1
                FROM follows f
                WHERE f.follower_email = %s
                  AND f.following_email = u.email
            ) AS is_following
        FROM group_members gm
        JOIN users u ON u.email = gm.user_email
        WHERE gm.group_id = %s
        ORDER BY gm.joined_at ASC, u.username ASC
        """,
        (
            viewer_email if viewer_email else "",
            group_id,
        )
    )

    rows = cur.fetchall()

    cur.close()
    conn.close()

    return {
        "users": [
            {
                "username": row[0],
                "email": row[1],
                "profile_image": row[2] if row[2] else "",
                "is_following": row[3],
            }
            for row in rows
        ]
    }


@app.delete("/groups/{group_id}")
def delete_group(
    group_id: int,
    email: str
):

    ensure_groups_tables()

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        cur.execute(
            """
            SELECT owner_email
            FROM groups
            WHERE id = %s
            """,
            (
                group_id,
            )
        )

        row = cur.fetchone()

        if row is None:

            raise HTTPException(
                status_code=404,
                detail="group not found"
            )

        owner_email = row[0]

        cur.execute(
            """
            SELECT 1
            FROM group_members
            WHERE group_id = %s
              AND user_email = %s
            """,
            (
                group_id,
                email,
            )
        )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=403,
                detail="not a group member"
            )

        if owner_email == email:

            cur.execute(
                """
                DELETE FROM groups
                WHERE id = %s
                """,
                (
                    group_id,
                )
            )

        else:

            cur.execute(
                """
                DELETE FROM group_members
                WHERE group_id = %s
                  AND user_email = %s
                """,
                (
                    group_id,
                    email,
                )
            )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "status": "ok"
    }


@app.post("/groups/{group_id}/members")
def add_group_members(
    group_id: int,
    data: AddGroupMembersRequest
):

    ensure_groups_tables()

    member_emails = {
        email.strip()
        for email in data.member_emails
        if email.strip()
    }

    if not member_emails:

        raise HTTPException(
            status_code=400,
            detail="member_emails is required"
        )

    conn = get_db_connection()

    cur = conn.cursor()

    try:

        cur.execute(
            "SELECT id FROM groups WHERE id = %s",
            (
                group_id,
            )
        )

        if cur.fetchone() is None:

            raise HTTPException(
                status_code=404,
                detail="group not found"
            )

        for member_email in member_emails:

            cur.execute(
                """
                INSERT INTO group_members (group_id, user_email)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING
                """,
                (
                    group_id,
                    member_email,
                )
            )

        conn.commit()

    except HTTPException:

        conn.rollback()

        raise

    except Exception as e:

        conn.rollback()

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    finally:

        cur.close()
        conn.close()

    return {
        "status": "ok"
    }


@app.post("/follow")
def follow_user(data: FollowRequest):

    ensure_follows_table()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        INSERT INTO follows (follower_email, following_email)
        VALUES (%s, %s)
        ON CONFLICT DO NOTHING
        """,
        (
            data.follower_email,
            data.following_email
        )
    )

    conn.commit()

    cur.close()
    conn.close()

    return {
        "status": "ok"
    }


@app.post("/unfollow")
def unfollow_user(data: FollowRequest):

    ensure_follows_table()

    conn = get_db_connection()

    cur = conn.cursor()

    cur.execute(
        """
        DELETE FROM follows
        WHERE follower_email = %s
          AND following_email = %s
        """,
        (
            data.follower_email,
            data.following_email
        )
    )

    conn.commit()

    cur.close()
    conn.close()

    return {
        "status": "ok"
    }
