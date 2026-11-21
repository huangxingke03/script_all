---
name: meegle-remark
description: "填写飞书项目工作项备注（评论）。用户给 project.feishu.cn 链接和备注内容时，用 Meegle CLI 写入 comment。默认只写正文，不上传日志、不打包、不调 attachment。只有用户这句话里包含「上传日志」时，才把分析结论和日志合成一条备注：正文写分析，日志作为同一条附件；多份原文件打成一个 zip 后一条上传，不要拆成两条、不要截取。Triggers on 填写备注、填写飞书项目备注、帮我填写备注、写一条备注、上传日志。Do not use for 飞书任务评论、飞书文档评论、工作项字段更新、导航/多媒体分析。 Ignore case."
metadata:
  short-description: Add Feishu Project work-item remarks
  requires:
    bins: ["meegle"]
---

# 填写飞书项目备注

把用户指定的文字写到飞书项目工作项评论里。这是 `project.feishu.cn` 工作项，不是飞书任务。用 `meegle comment add`，不要用 `lark-cli task +comment`。

缺链接时先问，不要猜。用户说按分析结论写备注 / 分析结论备注时，正文用本次分析的 1-5 段，不要再问正文。仅无语义下发时不要把 `本地：` 行写进备注，`提示` / `提示语` 仍保留；有语义下发则 1-5 段原文照抄，不要删行。已经给出内容和链接后直接写，不要再确认。

默认不上传日志。只看用户这一句话：包含「上传日志」才上传附件；说「不上传日志」、没提日志、或只说填写备注，都只写正文。不要因为手里有日志文件、分析技能记过日志路径、或备注正文来自日志分析就自行上传。

## 流程

1. 先读并执行 `../meegle/references/auth-guard.md`。有 URL 时先：

```bash
meegle url decode --url '<用户链接>' --format json
```

禁止自己从路径截 `project_key` / `work_item_id`。`url_kind` 必须是 `workitem_detail`，否则拒绝。

2. 无浏览器环境用 Device Code，不要跑会卡住的浏览器 OAuth：

```bash
meegle auth login --device-code --phase init --host "$host" --format json
```

把 `verification_uri_complete` 发给用户（URL 在前，二维码在后；二维码用 `lark-cli auth qrcode <url> --output /tmp/meegle-auth-qr.png`）。用户说已授权后：

```bash
meegle auth login --device-code --phase poll --host "$host" \
  --client-id '<client_id>' --device-code-value '<device_code>' --once --format json
```

3. 用 decode 得到的 `simple_name` 换权威 `project_key`：

```bash
meegle project search --project-key '<simple_name>' --format json
```

4. 写入备注。多行内容用 Python `json.dumps` 传 `--params`，不要 `--params /path.json`。默认只写正文，不带 `file_token`。用户这句话包含「上传日志」时，分析结论和日志才合成一条，不要拆成两条。

按分析结论写备注时，正文直接用本次 1-5 段输出，不要带 `日志文件` 行，不要改成有序列表。仅无语义下发时去掉 `本地：` 行，不要写进备注；有语义下发则 1-5 段原文照抄，不要删行。禁止为了塞附件把同一段分析结论写多次。

未包含「上传日志」：不要跑 `pack-log-files.py`，不要 `attachment +upload`，不要在 `comment add` 里带 `file_token`。

包含「上传日志」时，先准备附件，再和正文一起 `comment add` 一次：

- 日志以分析技能标出的文件为准。确认存在、可读。禁止按时间窗截取、切片、另存精简版。
- 评论附件 `resource-type=13`，不要填 `field-key`。`file_token` 一次只能填一个，且只能在创建时带上。
- **禁止**对已有备注 `--action update` 带 `file_token`（接口报 `file attachment cannot be updated`）。
- 1 个文件：直接上传原文件，`--filename` 用原名。
- **多个日志文件必须先压缩再上传**：用本技能 `scripts/pack-log-files.py` 把全部原文件打成一个 zip（zip 内保持原名，store 不压缩，不改内容），只上传这个 zip，不要逐个原文件上传：

```bash
python3 /home/huangxingke/.agents/skills/meegle-remark/scripts/pack-log-files.py <file1> <file2>
meegle attachment +upload '<local-path>' --resource-type 13 --project-key '<project_key>' --work-item-id '<work_item_id>' --filename '<name>' --format json
```

默认只写正文。包含「上传日志」且已有附件时，同一条带上 `file_token`：

```bash
meegle comment add --params '{"project_key":"...","work_item_id":"...","content":"..."}' --format json
meegle comment add --params '{"project_key":"...","work_item_id":"...","content":"...","file_token":"..."}' --format json
```

`success: true` 才算写上。成功后只报链接、内容、是否附上了整份日志和结果。默认未附日志，要写明未上传。不要展开 Meegle 其他能力。

用户说编号乱了、没换行、优化格式时，用 `comment list` 取最近一条，`--action update --comment-id` 覆盖，不要再新加一条。

## 飞书 markdown

飞书项目评论会把 markdown 有序列表 `1.` 后的换行拼进同一行，并在 `-` 列表后把编号重置成 `1.`。

- 不要用有序列表 `1.`
- 标题写成 `**1. ...**`
- 标题和下一行之间空一行，段与段空一行
- 不要嵌套 markdown 编号
