from google.adk.agents import Agent, SequentialAgent
from .config import get_model
from .material_generator import material_gen_and_teacher_agent
from google.adk.tools.agent_tool import AgentTool

topic_keyword_agent = Agent(
    model=get_model(),
    name="topic_keyword_agent",
    description="ユーザーから学習トピックに関する情報を受け取り、その情報からキーワードを抽出し、さらにサブトピックに分解するエージェント",
    instruction="""
- 前述のユーザーから学習トピックに関する情報(キーワード、画像情報)から、キーワードを3つ抽出してください。
- その各キーワードから関連するサブトピックをさらに2つ抽出してください。

[出力形式]
{
  "topics": [
     {"keyword": "キーワード1", "sub_topics": ["サブトピック1", "サブトピック2"]},
     {"keyword": "キーワード2", "sub_topics": ["サブトピック1", "サブトピック2"]},
     {"keyword": "キーワード3", "sub_topics": ["サブトピック1", "サブトピック2"]},
  ]
}
""",
    output_key="topics",
    disallow_transfer_to_parent=True,
    disallow_transfer_to_peers=True,
) 

topic_sentence_agent = Agent(
    model=get_model(),
    name="topic_sentence_agent",
    description="受け取ったキーワードとサブトピックを組み合わせて、学習内容を簡潔にまとめるエージェント",
    instruction="""
受け取ったキーワードとサブトピックを組み合わせて、学習内容を簡潔にまとめてください。

[topics]
{topics}

[学習内容のポイント]
学習内容`sentence`は、各`keyword`に対して、`sub_topics`の内容を簡潔に含めてユーザが学びたい内容をまとめたものです。

[出力形式]
{
  "topics": [
     {"keyword": "キーワード1", "sub_topics": ["サブトピック1", "サブトピック2"], "sentence": "学習内容A"},
     {"keyword": "キーワード2", "sub_topics": ["サブトピック1", "サブトピック2"], "sentence": "学習内容B"},
     {"keyword": "キーワード3", "sub_topics": ["サブトピック1", "サブトピック2"], "sentence": "学習内容C"},
  ]
}
""",
    output_key="topic_sentences",
    disallow_transfer_to_parent=True,
    disallow_transfer_to_peers=True,
) 

topic_generator_agent = SequentialAgent(
    name="topic_generator_agent",
    description="ユーザーから学習トピックに関する情報を受け取り、その情報からキーワードを抽出し、さらにサブトピックに分解するエージェント",
    sub_agents=[topic_keyword_agent, topic_sentence_agent],
) 


topic_hearing_agent = Agent(
    model=get_model(),
    name="topic_hearing_agent",
    description="ユーザーに対して挨拶と感じ良い対応をしながら、何を学習したいか聞き出すエージェント",
    instruction="""
1. 軽い挨拶があれば、感じよく対応し、何を学習したいかを聞き出します。
2. 学習トピックに関するキーワード、または画像情報を受け取らなかった場合、1に戻り、何を学習したいか聞き出し、相談に乗ります。
3. 学習トピックに関するキーワード、または画像情報を受け取ったら、topic_generator_agent を呼び出して、学習トピックを生成してください。
4. その学習トピックで問題ないか、ユーザーに伺います。
5. その内容でOKであれば、material_gen_and_teacher_agentに委譲してください。
6. その内容でNGであれば、1に戻ります。

[注意]
学習に関係のない質問には、あまり答えず、何を学習したいかに関連する話題に誘導します。
""",
    sub_agents=[material_gen_and_teacher_agent],
    tools=[AgentTool(topic_generator_agent)],
) 
