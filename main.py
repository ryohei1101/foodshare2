from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import psycopg2
from passlib.hash import bcrypt
from fastapi.staticfiles import StaticFiles

app = FastAPI()
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# DB接続
conn = psycopg2.connect(
    dbname="account_manage",
    user="ryohe1101",
    password="",
    host="localhost"
)

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
        "SELECT uuid, username, password_hash, role, birthday, email FROM users WHERE email = %s",
        (data.email,)
    )
    user = cur.fetchone()

    if not user:
        raise HTTPException(status_code=401, detail="ユーザー不存在")

    uuid, username, password_hash, role, birthday, email = user

    # ⭐ 本当はbcrypt使うべき
    if data.password != password_hash:
        raise HTTPException(status_code=401, detail="パスワード不一致")

    cur.close()
    conn.close()

    return {
        "message": "ログイン成功",
        "uuid": uuid,
        "username": username,
        "role": role,
        "birthday": str(birthday) if birthday else "",
        "email": email
    }


from fastapi import FastAPI
from pydantic import BaseModel
import psycopg2
import uuid
from datetime import datetime
import bcrypt


class User(BaseModel):
    email: str
    password: str
    username: str
    gender: str
    birthday: str  # "YYYY-MM-DD"

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

        cur.execute("""
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
            VALUES (%s, %s, %s, NOW(), %s, %s, %s, %s, %s)
        """, (
            user.username,
            user.email,
            user.password,
            True,
            "user",
            str(uuid.uuid4()),
            user.gender,
            user.birthday
        ))

        conn.commit()
        print("INSERT成功")

        cur.close()
        conn.close()

        return {"status": "ok"}

    except Exception as e:
        print("エラー内容↓↓↓↓↓↓↓↓")
        print(e)
        return {"status": "error", "detail": str(e)}