# from google.adk.models.lite_llm import LiteLlm

def get_model():
    # localのollamaを使用する場合
    # return LiteLlm(model="openai/qwen3:4b")
    # return LiteLlm(model="openai/hf.co/unsloth/Qwen3-30B-A3B-GGUF:Q3_K_XL")

    # googleのgeminiを使用する場合
    # return "gemini-2.0-flash"
    return "gemini-2.5-flash-preview-05-20"
