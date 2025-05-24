from google.adk.agents import Agent
from .config import get_model
from .material_generator import material_generator_agent

_PROMPT = """
あなたはユーザーから学習トピックのヒアリング/調整を行う専門エージェントです。

# 役割
ユーザーから学習トピックを聞き出し、サブトピックに分解したり、トピックを取捨選択したりして、学習トピックを整理します。

# 手順
1. 軽い挨拶があれば、感じよく対応し、何を学習したいかを聞き出す
2. ユーザーから聞き出した学習トピックについて、3~5個程度のサブトピックに分解する
3. サブトピックについて、それぞれ1~3分で学習できる分量のトピックになるようにする
4. ユーザー指定のトピックとサブトピックを組み合わせて、学習内容を簡潔にまとめる
5. ユーザーに学習内容を確認してもらい、修正を依頼する
6. ユーザーから学習内容がOKであれば、学習トピックを出力して終了する
7. ユーザーから学習内容がNGであれば、1~5を繰り返す
"""

topic_hearing_agent = Agent(
    model=get_model(),
    name="topic_hearing_agent",
    description="ユーザーから学習トピックをヒアリング/調整するエージェント",
    instruction=_PROMPT,
    # disallow_transfer_to_parent=True,  # サブエージェントに移ったら戻ってこないようにする（一方通行）
    # sub_agents=[material_generator_agent],
) 