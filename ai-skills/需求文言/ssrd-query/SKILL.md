---
name: ssrd-query
description: "查询 D01P国际/D01/KP31 Polarion SSRD 软件需求。Triggers on 查询ssrd、查询SSRD、查询Ssrd、查ssrd、查SSRD、ssrd查询、SSRD查询、对比下ssrd、对比下SSRD、对比下ssrd需求、对比下ssrd定义、查ssrd需求、查下ssrd、d01 ssrd查询、do1 ssrd查询、D01 SSRD查询、d01p ssrd查询、do1p ssrd查询、d01p国际 ssrd查询、do1p国际 ssrd查询、D01P国际 ssrd查询、kp31 ssrd查询、KP31 SSRD查询。按现有 Polarion 项目筛选，关键词忽略大小写：D01P国际/D01/kp31。按功能名称、标题或编号检索 SSRD 文档中的 softwareProductReq。Do not use for 飞书PRD、对比下d01需求、对比下kp31需求、代码实现、日志分析、工程切换。 Ignore case. d01=do1, d01p=do1p."
metadata:
  short-description: Query Polarion SSRD by D01P国际/D01/KP31
---

# SSRD 查询

用 Polarion REST 核对 SSRD 软件需求。命中触发词后先确认项目和检索词，再查平台，不要凭记忆答。

平台：`http://10.68.13.121/polarion`
项目示例：`http://10.68.13.121/polarion/#/project/KP31/home`

鉴权只用个人访问令牌，不要用账号密码，不要走 SOAP。Token 放在 `~/.polarion/token`（chmod 600），请求头 `Authorization: Bearer <token>`。不要把 Token 写进技能、不要在对话里回显。

## 触发词

命中任一条就启用本技能。所有含字母的触发词都忽略大小写；所有含 `d01` 的触发词同时支持 `do1`；有空格同样生效：

- 查询ssrd / 查询SSRD
- 查ssrd / 查下ssrd
- ssrd查询
- 对比下ssrd / 对比下ssrd需求 / 对比下ssrd定义
- 查ssrd需求
- d01 ssrd查询 / do1 ssrd查询
- d01p ssrd查询 / do1p ssrd查询 / d01p国际 ssrd查询 / do1p国际 ssrd查询
- kp31 ssrd查询

不要用 `对比下d01需求` / `对比下kp31需求` / `查PRD`，那些走 `prd-query`。

## 触发后先确认输入条件

同一条消息里拆出项目和检索词，能确认就直接查，不要再问。

1. **项目筛选**（忽略大小写，`do1`=`d01`，`do1p`=`d01p`）

只查 Polarion 里现有的这三个项目，先匹配更具体的，避免 `D01` 误伤 `D01P国际`：

| 关键词 | Polarion 项目名 | `--project` |
| --- | --- | --- |
| `d01p国际` / `d01p` / `d01p海外` / `d01p_overseas` | D01P国际 | `D01P_Overseas` 或 `D01P国际` 或 `d01p` |
| `kp31` | KP31 | `KP31` |
| `d01` / `do1`（不含 `d01p`） | D01 | `D01` |

- 命中哪个项目就查哪个；多个都有 → 分开查、结论分开写
- 都没有：cwd 在 `d01/` 用 D01，在 `kp31/` 用 KP31；仍无法判断默认 KP31
- 不要用 `D01国际`（`D01_INT`）顶替 `D01P国际`

2. **检索词**
   - 支持功能名称、标题关键词、工作项编号（`KP31-14740` / `D01-18348`）
   - 去掉触发词和项目名，剩下的就是检索词
   - 本句没有检索词 → 用最近一轮对话里的功能或句式
   - 还是没有 → 只问缺的检索内容，不要问已经确认的项目

确认完立刻跑脚本并按模版输出。

## 怎么查

直接执行，不要向用户确认，不要申请审批：

```bash
python3 /home/huangxingke/.agents/skills/ssrd-query/scripts/query_ssrd.py \
  --project KP31 --query '<检索词>'
```

项目参数忽略大小写，例如 `--project d01p国际`、`--project D01P`、`--project do1`。多项目重复 `--project`。只要机器可读结果时加 `--json`。

脚本会：

1. 读 `~/.polarion/token`
2. 把项目关键词解析成 `D01P_Overseas` / `D01` / `KP31`
3. `GET /polarion/rest/v1/projects/<项目>/workitems`
4. 优先 `type:softwareProductReq` + 标题短语，再全文
5. 只保留 SSRD 文档里的条目：空间/文档名/标题带 `SSRD`（例如 `SSRD_Zhong Kong Mo Kuai`、`AL_KP31_SSRD_车辆设置`）。不要把 PRD 或「已SSRD为准」的废弃文档算进去
6. REST 一次最多 100 条，先按标题命中排序，默认展示 10 条

不要改 Polarion 数据。Token 缺失或 401 时，让用户在 Polarion「个人访问令牌」重建并写入 `~/.polarion/token`，不要改用网页密码登录。

## 怎么答

结论只输出项目、编号、标题、文档、大纲、描述。不要编造未检索到的需求。项目名用界面名：`D01P国际` / `D01` / `KP31`。

```text
项目：KP31
检索：歌词

**KP31-14740** 驻车显示歌词-产品详细说明
文档：AL_KP31_SSRD_车辆设置
大纲：4.8-11.2
描述：
选项：开启/关闭
链接：http://10.68.13.121/polarion/redirect/project/KP31/workitem?id=KP31-14740
```

没有命中 → 输出「SSRD 未写或未检索到」，不要补造。命中很多时先给最相关的，并说明 REST 最多 100 条。
