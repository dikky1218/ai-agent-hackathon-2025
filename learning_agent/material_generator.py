from google.adk.agents import Agent
from .config import get_model


_PROMPT = """
あなたは学習教材を生成する専門エージェントです。

# 学習トピック
ユーザーとのやり取りの中で最終的に決定した学習トピックを採用してください。

# 役割
学習トピックから15分で学習できる学習教材を生成してください。
1. 1つのトピックに割り当てる学習時間を計算(15分 / トピックの数)
2. 1つめのトピックについて、割り当て学習時間に合わせて、学習内容を生成する
3. 2.を繰り返し、全てのトピックについて学習内容を生成する
4. 生成した学習内容をまとめて、学習教材を生成する

# 出力形式
- 学習教材はMarkdown形式で出力してください
- 学習教材には、学習トピック、学習内容、学習時間が含まれている必要があります

"""

material_generator_agent = Agent(
    model=get_model(),
    name="material_generator_agent",
    description="ユーザーが決定した学習トピック群から、学習教材を生成する専門エージェント",
    instruction=_PROMPT,
    disallow_transfer_to_parent=True,  # 一方通行
    disallow_transfer_to_peers=True,  # 一方通行
) 