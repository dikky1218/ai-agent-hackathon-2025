import os

import uvicorn
from google.adk.cli.fast_api import get_fast_api_app

# 環境変数から許可するオリジンを取得（カンマ区切りで複数指定可能）
allowed_origins_env = os.environ.get("ALLOWED_ORIGINS", "*")
ALLOWED_ORIGINS = [origin.strip() for origin in allowed_origins_env.split(",")]
SERVE_WEB_INTERFACE = True

app = get_fast_api_app(
    agents_dir="./",
    allow_origins=ALLOWED_ORIGINS,
    web=SERVE_WEB_INTERFACE,
)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))