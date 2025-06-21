from google.adk.agents import Agent
from google.adk.tools.agent_tool import AgentTool
from .config import get_model
from .teacher import teacher_agent


_PROMPT = """
あなたは学習教材を生成する専門エージェントです。

# 学習トピック
{topic_sentences}

# 役割
- 学習トピックの各キーワードに対して、1分で学習できる学習教材を生成します。

# 出力形式
- 学習教材はMarkdown形式で出力してください
- 各キーワードをh1見出しにしてください
  - サブトピックはh2見出しで出力します。
  - サブトピックのh2見出しの下にsentenceに対応する学習テキストを出力します
    - 学習テキストは、リストや表などで視覚的にわかりやすくしてください
    - 学習テキストに含める文章は簡潔に2~3文にしてください
- 最後にh1見出しとして「まとめ」セクションを追加します。
  - 学習内容を簡潔にまとめます。
  - ここではh2見出しを使わず、リストでまとめます。
- また、h1セクションの間には`---`を挿入してください

# 出力例
```markdown
---
# キーワード1
## サブトピック1
学習テキスト1

## サブトピック2
学習テキスト2

---
# キーワード2
## サブトピック1
学習テキスト1

## サブトピック2
学習テキスト2
---
# キーワード3
## サブトピック1
学習テキスト1

## サブトピック2
学習テキスト2
---
# まとめ
キーワード1~3の学習内容の簡潔なまとめ
---
```
"""

material_generator_agent = Agent(
    model=get_model(is_pro=True),
    name="material_generator_agent",
    description="与えられた学習トピックから、学習教材を生成するエージェント",
    instruction=_PROMPT,
    disallow_transfer_to_parent=True,
    disallow_transfer_to_peers=True,
    include_contents='none',
    output_key="material",
) 

material_gen_and_teacher_agent = Agent(
    name="material_gen_and_teacher_agent",
    description="学習教材を生成し、その内容に関する相談を受け付けるエージェント",
    instruction="""
1. material_generator_agentを呼び出して、学習教材を生成してください。
2. 生成された学習教材をそのまま表示します。
3. その後のユーザーとのやりとりに関しては、teacher_agentを呼び出して行います。

# 2.における出力形式
学習教材を作成しました。
---
学習教材のマークダウン(h1見出しの間に`---`を挿入してください)
---
わからないことがあれば、なんでも質問してください。

""",
    tools=[AgentTool(material_generator_agent)],
    sub_agents=[teacher_agent],
) 