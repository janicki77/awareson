from flask import Flask, render_template, request
from db import get_connection

app = Flask(__name__)

@app.route('/')
def index():
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("SELECT message FROM messages")
    messages = cursor.fetchall()
    conn.close()
    return render_template('index.html', messages=messages)

@app.route('/submit', methods=['POST'])
def submit():
    message = request.form['message']
    conn = get_connection()
    cursor = conn.cursor()
    cursor.execute("INSERT INTO messages (message) VALUES (%s)", (message,))
    conn.commit()
    conn.close()
    return ('', 204)

@app.route('/health/db')
def health():
    try:
        conn = get_connection()
        conn.close()
        return "Database connected", 200
    except:
        return "Database connection failed", 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
