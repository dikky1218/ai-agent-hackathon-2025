from google.adk.agents import Agent
from .config import get_model
from .material_generator import material_generator_agent
from .topic_hearing import topic_hearing_agent
from .casual_talk import casual_talk_agent
from .teacher import teacher_agent
from .exam_listener import exam_listener_agent
from .exam_evaluator import exam_evaluator_agent

# 学習アシスタントエージェント
root_agent = Agent(
    name="learning_assistant_agent",
    model=get_model(),
    description="ユーザーの学習を手順に従ってサポートするcoordinatorエージェント",
    instruction="""
あなたはユーザーの学習をサポートするエージェントです。
ユーザーの学習トピックを聞き出し、学習教材を生成し、その学習と定着をサポートします。

# [役割]
- [手順]にしたがって、ユーザーの学習をサポートします。
- 学習に関係ない質問には、あまり答えず、学習に関連する話題に誘導します。

# [手順]
1. ユーザーの学習トピックを聞き出す
2. 学習教材を生成する
3. ユーザーが教材を学習完了するまで、学習をサポートする
4. ユーザーが学習した内容をプレゼンするので、聞き役をする
5. ユーザーのプレゼン後、評価し、採点、フィードバックをする
6. 今回の学習を「お疲れさまでした！」と褒めて締めくくり、プレゼン結果をもとに次の学習を提案して終了する

# [sub agents]
- 学習トピックを聞き出す際には、topic_hearing_agentを使用してください。
- 学習教材を生成する際には、material_generator_agentを使用してください。
- 学習している生徒と息抜きの雑談をする際には、casual_talk_agentを使用してください。
- 学習教材に関する相談は、teacher_agentを使用してください。
- プレゼンの聞き役は、 exam_listener_agent を使用してください。
- プレゼン後評価は、 exam_evaluator_agent を使用してください。
    """,
    sub_agents=[topic_hearing_agent, material_generator_agent, casual_talk_agent, teacher_agent, exam_listener_agent, exam_evaluator_agent],
) 