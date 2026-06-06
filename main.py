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
            category TEXT NOT NULL,
            price_range TEXT NOT NULL,
            location TEXT NOT NULL,
            comment TEXT NOT NULL,
            latitude DOUBLE PRECISION,
            longitude DOUBLE PRECISION,
            created_at TIMESTAMP DEFAULT NOW()
        )
        """
    )

    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION")
    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION")
    cur.execute("ALTER TABLE posts ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()")

    conn.commit()

    cur.close()
    conn.close()

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

    category: str = Form(...),

    price_range: str = Form(...),

    location: str = Form(...),

    comment: str = Form(...),

    latitude: Optional[float] = Form(None),

    longitude: Optional[float] = Form(None),

    file: UploadFile = File(...)
):

    try:

        ensure_posts_table()

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
                category,
                price_range,
                location,
                comment,
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
                %s
            )
            """,
            (
                user_email,
                file_path,
                category,
                price_range,
                location,
                comment,
                latitude,
                longitude
            )
        )

        conn.commit()

        cur.close()

        conn.close()

        return {

            "message": "post success",

            "image_path": file_path
        }

    except Exception as e:

        print("post upload error")

        print(e)

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
