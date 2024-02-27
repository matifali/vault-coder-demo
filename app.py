from flask import Flask
import os

# loading secrets from local .env file
from pathlib import Path
from dotenv import load_dotenv
env_file_name = ".env"
env_path = Path.cwd().joinpath(f"env/{env_file_name}")
load_dotenv(dotenv_path=env_path)

app = Flask(__name__)

@app.route('/')
def show_env_variables():
    # List of environment variables to display
    vars_to_display = ['SECRET_1', 'SECRET_2']
    env_vars = '<br>'.join([f'{var}: {os.environ.get(var, "Not Found")}' for var in vars_to_display])
    return f'<h1>Project Secrets</h1><p>{env_vars}</p>'
if __name__ == '__main__':
    app.run(debug=True, port=5000)
