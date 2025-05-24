from google.adk.models.lite_llm import LiteLlm

def get_model():
    # localのollamaを使用する場合
    return LiteLlm(model="openai/qwen3:4b")

    # googleのgeminiを使用する場合
    # return "gemini-2.0-flash"
