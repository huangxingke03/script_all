#!/bin/bash

# Feishu download configuration
#
# Recommended usage:
# 1. Open the target Feishu issue detail page in the browser.
# 2. In DevTools, copy the issue-detail request as cURL (bash).
# 3. Paste the full cURL text into `download_feishu_request.curl`.
# 4. Keep `FEISHU_CURL_EXPORT_FILE` pointing at that file.
#
# JIRA-history attachment usage:
# - If Feishu returns Jira-history attachment URLs, the downloader can extract a
#   separate JIRA cookie directly from `download_jira_request.curl`.
# - Keep `FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE` pointing at that file, or set
#   `FEISHU_ATTACHMENT_JIRA_COOKIE` manually as a fallback.
#
# Browser-exported request used for extracting Feishu cookie / referer / user-agent.
CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FEISHU_CURL_EXPORT_FILE="${CONFIG_DIR}/download_feishu_request.curl"

# Browser-exported JIRA request used only when Feishu returns Jira-history attachment URLs.
# The downloader extracts the Cookie value from this cURL at runtime.
FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE="${CONFIG_DIR}/download_jira_request.curl"

# Direct Feishu cookie fallback. Use the full Cookie header value only, without the `Cookie:` prefix.
# Example:
# FEISHU_COOKIE="session=...; meego_csrf_token=...; meego_local=28800"
# FEISHU_COOKIE=""

# Optional direct JIRA-history attachment cookie fallback. Usually keep this empty and let
# `FEISHU_ATTACHMENT_JIRA_CURL_EXPORT_FILE` provide the cookie automatically.
# Example:
# FEISHU_ATTACHMENT_JIRA_COOKIE="JSESSIONID=...; atlassian.xsrf.token=...; seraph.rememberme.cookie=..."
# FEISHU_ATTACHMENT_JIRA_COOKIE=""

# Optional referer fallback. Usually keep this empty unless the exported cURL omits Referer.
# Example:
# FEISHU_REFERER_FALLBACK="https://project.feishu.cn/sb69eb/issue/detail/7042888694?parentUrl=%2Fworkbench&openScene=3"
# FEISHU_REFERER_FALLBACK=""

# Optional user-agent fallback. Usually keep this empty unless the exported cURL omits User-Agent.
# Example:
# FEISHU_USER_AGENT_FALLBACK="Mozilla/5.0 ... Chrome/143.0.0.0 Safari/537.36"
# FEISHU_USER_AGENT_FALLBACK=""

# Optional request URL fallback. Use this only when the exported cURL is incomplete.
# Example:
# FEISHU_REQUEST_URL_FALLBACK="https://project.feishu.cn/goapi/v2/projects/.../work_item/issue/7042888694?"
# FEISHU_REQUEST_URL_FALLBACK=""
