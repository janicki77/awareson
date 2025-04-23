from flask import Flask, render_template, request
import mysql.connector
import os

app = Flask(__name__)

def get_db_connection():
    return mysql.connector.connect(
        host=os.getenv("MYSQL_HOST"),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DB")
    )

@app.route('/', methods=['GET', 'POST'])
def index():
    conn = get_db_connection()
    cursor = conn.cursor()
    if request.method == 'POST':
        name = request.form['name']
        cursor.execute("INSERT INTO users (name) VALUES (%s)", (name,))
        conn.commit()
    cursor.execute("SELECT name FROM users")
    users = cursor.fetchall()
    conn.close()
    return render_template('index.html', users=users)

@app.route('/health')
def health():
    try:
        conn = get_db_connection()
        conn.close()
        return 'OK', 200
    except:
        return 'DB connection failed', 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)