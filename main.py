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

from datetime import datetime

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


# =========================
# ⭐ Login
# =========================
class LoginRequest(BaseModel):

    email: str
    password: str


class FollowRequest(BaseModel):

    follower_email: str
    following_email: str


@app.post("/login")
def login(data: LoginRequest):

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


@app.post("/register")
def register(user: User):

    print(user)

    try:

        conn = psycopg2.connect(
            dbname="account_manage",
            user="ryohe1101",
            password="",
            host="localhost"
        )

        cur = conn.cursor()

        print("INSERT前")

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
                birthday

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
                %s
            )
            """,
            (
                user.username,

                user.email,

                user.password,

                True,

                "user",

                str(uuid.uuid4()),

                user.gender,

                user.birthday
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

        print("エラー内容↓↓↓↓↓↓↓↓")

        print(e)

        return {
            "status": "error",
            "detail": str(e)
        }

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
    location: Optional[str] = None,
    price_range: Optional[str] = None,
    category: Optional[str] = None,
    tag: Optional[str] = None,
    limit: int = 50
):

    ensure_posts_table()

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

    if location:

        conditions.append("p.location ILIKE %s")

        params.append(f"%{location}%")

    if price_range:

        conditions.append("p.price_range = %s")

        params.append(price_range)

    if category:

        conditions.append("p.category = %s")

        params.append(category)

    if tag:

        conditions.append("(p.tags ILIKE %s OR p.comment ILIKE %s)")

        params.extend([f"%{tag}%", f"%{tag}%"])

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


@app.get("/users")
def get_users(
    exclude_email: Optional[str] = None,
    viewer_email: Optional[str] = None,
    query: Optional[str] = None,
    limit: int = 100
):

    ensure_follows_table()

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

        conditions.append("(COALESCE(u.username, '') ILIKE %s OR u.email ILIKE %s)")

        params.extend([f"%{search_query}%", f"%{search_query}%"])

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
