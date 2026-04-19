#!/bin/bash
set -euo pipefail

# 火山CodingPlan用量查询脚本
# 支持多账号、格式化输出、错误处理、一键导入curl请求

# 配置文件路径
CONFIG_FILE="$HOME/.codingplan-usage.conf"
DEFAULT_ACCOUNT="default"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 显示帮助信息
show_help() {
    cat << EOF
用法: $(basename "$0") [命令] [选项]

命令:
    query [选项]        查询用量（默认命令）
    import [选项]       从curl请求导入配置
    config list         列出所有配置的账号
    config remove <名称> 删除指定账号
    help                显示帮助信息
    version             显示版本信息

查询选项:
    -a, --account <名称>   查询指定账号的用量
    -j, --json             输出JSON格式
    -s, --short            输出简洁格式（适合状态栏）

导入选项:
    -a, --account <名称>   导入到指定账号（默认: default）
    -f, --file <路径>      从文件读取curl请求
    --no-verify            导入前不验证配置有效性

示例:
    # 直接粘贴curl请求导入
    ./codingplan-query.sh import
    # 然后直接粘贴你抓的整个curl命令，按Ctrl+D结束

    # 从剪贴板导入（macOS）
    pbpaste | ./codingplan-query.sh import

    # 从文件导入
    ./codingplan-query.sh import -f curl-request.txt

    # 导入到指定账号
    ./codingplan-query.sh import -a company
EOF
}

# 显示版本
show_version() {
    echo "codingplan-query v1.2.0"
}

# 检查依赖
check_dependencies() {
    if ! command -v curl &> /dev/null; then
        echo -e "${RED}错误: 未找到curl，请先安装curl${NC}" >&2
        exit 1
    fi
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}错误: 未找到jq，请先安装jq (brew install jq)${NC}" >&2
        exit 1
    fi
    if ! command -v bc &> /dev/null; then
        echo -e "${RED}错误: 未找到bc，请先安装bc (brew install bc)${NC}" >&2
        exit 1
    fi
}

# 检查配置文件
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}配置文件不存在，正在创建模板...${NC}"
        cat > "$CONFIG_FILE" << EOF
# CodingPlan 用量查询配置文件
# 可以通过 ./codingplan-query.sh import 命令直接导入curl请求自动生成配置
# 也可以手动填写，格式如下:
# [default]
# connect_sid = "s%3Axxxx..."
# digest = "eyJhbGciOiJSUzI1NiIs..."
# csrf_token = "2f237a038f..."

[default]
connect_sid = ""
digest = ""
csrf_token = ""
EOF
        chmod 600 "$CONFIG_FILE"
        echo -e "${GREEN}已创建配置文件模板: $CONFIG_FILE${NC}"
        echo ""
    fi

    # 检查文件权限
    current_perm=$(stat -f "%Lp" "$CONFIG_FILE" 2>/dev/null || stat -c "%a" "$CONFIG_FILE" 2>/dev/null)
    if [ "$current_perm" != "600" ]; then
        echo -e "${YELLOW}警告: 配置文件权限不安全，正在修改为600...${NC}"
        chmod 600 "$CONFIG_FILE"
    fi
}

# 读取配置
read_config() {
    local account="$1"
    local key="$2"

    # 简单的INI解析，支持[section]和key=value格式
    awk -v section="$account" -v key="$key" '
    BEGIN { in_section = 0 }
    /^\[.*\]$/ {
        gsub(/[\[\]]/, "", $0)
        in_section = ($0 == section)
        next
    }
    in_section && /^[[:space:]]*[^#=]+[[:space:]]*=/ {
        split($0, parts, "=")
        k = trim(parts[1])
        v = trim(parts[2])
        gsub(/^["'\'']|["'\'']$/, "", v) # 移除引号
        if (k == key) print v
    }
    function trim(s) { gsub(/^[[:space:]]+|[[:space:]]+$/, "", s); return s }
    ' "$CONFIG_FILE"
}

# 保存配置
save_config() {
    local account="$1"
    local connect_sid="$2"
    local digest="$3"
    local csrf_token="$4"

    # 先读取现有配置，排除要更新的账号
    temp_file=$(mktemp)
    awk -v section="$account" '
    BEGIN { skip = 0 }
    /^\[.*\]$/ {
        gsub(/[\[\]]/, "", $0)
        skip = ($0 == section)
        if (!skip) print "[" $0 "]"
        next
    }
    !skip && !/^[[:space:]]*$/ && !/^[[:space:]]*#/ { print }
    ' "$CONFIG_FILE" > "$temp_file"

    # 追加新的配置
    cat >> "$temp_file" << EOF

[$account]
connect_sid = "$connect_sid"
digest = "$digest"
csrf_token = "$csrf_token"
EOF

    # 替换原文件
    mv "$temp_file" "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
}

# 列出所有账号
list_accounts() {
    echo -e "${BLUE}已配置的账号:${NC}"
    awk '
    /^\[.*\]$/ {
        gsub(/[\[\]]/, "", $0)
        print "  - " $0
    }
    ' "$CONFIG_FILE"
}

# 删除账号
remove_account() {
    local account="$1"

    if [ -z "$(read_config "$account" "connect_sid")" ]; then
        echo -e "${RED}错误: 账号 '$account' 不存在${NC}" >&2
        exit 1
    fi

    temp_file=$(mktemp)
    awk -v section="$account" '
    BEGIN { skip = 0 }
    /^\[.*\]$/ {
        gsub(/[\[\]]/, "", $0)
        skip = ($0 == section)
        if (!skip) print "[" $0 "]"
        next
    }
    !skip { print }
    ' "$CONFIG_FILE" > "$temp_file"

    mv "$temp_file" "$CONFIG_FILE"
    echo -e "${GREEN}已删除账号: $account${NC}"
}

# 验证配置有效性
verify_config() {
    local connect_sid="$1"
    local digest="$2"
    local csrf_token="$3"

    echo -e "${BLUE}正在验证配置有效性...${NC}"

    # 构造Cookie
    cookie="connect.sid=$connect_sid; digest=$digest; csrfToken=$csrf_token"

    # 发送测试请求
    response=$(curl -s -w "\n%{http_code}" "https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage" \
        -H "content-type: application/json" \
        -H "referer: https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application" \
        -H "origin: https://console.volcengine.com" \
        -H "x-csrf-token: $csrf_token" \
        -b "$cookie" \
        --data-raw '{}' \
        --connect-timeout 5 \
        --max-time 10)

    # 分离响应体和状态码（兼容macOS）
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    if [ "$http_code" -ne 200 ]; then
        if [ "$http_code" -eq 401 ] || [ "$http_code" -eq 403 ]; then
            echo -e "${RED}验证失败: 认证信息无效或已过期${NC}" >&2
        else
            echo -e "${RED}验证失败: HTTP错误 $http_code${NC}" >&2
        fi
        return 1
    fi

    # 检查返回是否成功
    if echo "$body" | jq -e '.ResponseMetadata' >/dev/null 2>&1; then
        echo -e "${GREEN}✅ 配置验证成功！${NC}"
        return 0
    else
        error_msg=$(echo "$body" | jq -r '.message // "未知错误"' 2>/dev/null || echo "未知错误")
        echo -e "${RED}验证失败: $error_msg${NC}" >&2
        return 1
    fi
}

# 从curl请求中提取参数
parse_curl() {
    local input="$1"

    # 提取Cookie参数（-b 或 --cookie 后面的值）
    cookie=$(echo "$input" | grep -oE '(^|[[:space:]])-(b|-cookie)[[:space:]=]+("'"'"'?)([^"'"'"']*)\2' | sed -E 's/^[[:space:]]*-(b|-cookie)[[:space:]=]+["'"'"']?//' | sed -E 's/["'"'"']?$//')

    if [ -z "$cookie" ]; then
        echo -e "${RED}错误: 未找到Cookie参数，请确保输入的是完整的curl请求${NC}" >&2
        return 1
    fi

    # 提取各个字段
    connect_sid=$(echo "$cookie" | grep -oE 'connect\.sid=[^;]*' | cut -d'=' -f2 | head -n1)
    digest=$(echo "$cookie" | grep -oE 'digest=[^;]*' | cut -d'=' -f2 | head -n1)
    csrf_token=$(echo "$cookie" | grep -oE 'csrfToken=[^;]*' | cut -d'=' -f2 | head -n1)

    # 如果Cookie中没有csrfToken，尝试从请求头提取
    if [ -z "$csrf_token" ]; then
        csrf_token=$(echo "$input" | grep -oE '(^|[[:space:]])-H[[:space:]=]+("'"'"'?)x-csrf-token:\s*\2([^"'"'"']*)\2' | sed -E 's/^[[:space:]]*-H[[:space:]=]+["'"'"']?x-csrf-token:\s*//i' | sed -E 's/["'"'"']?$//' | head -n1)
    fi

    # 检查是否提取完整
    local missing=()
    [ -z "$connect_sid" ] && missing+=("connect_sid")
    [ -z "$digest" ] && missing+=("digest")
    [ -z "$csrf_token" ] && missing+=("csrf_token")

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}错误: 未能提取到完整的参数，缺少: ${missing[*]}${NC}" >&2
        echo -e "请确保输入的curl请求包含完整的Cookie信息${NC}" >&2
        return 1
    fi

    # 输出提取到的参数
    echo "$connect_sid|$digest|$csrf_token"
    return 0
}

# 导入配置
import_config() {
    local account="$DEFAULT_ACCOUNT"
    local file=""
    local verify=true

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--account)
                account="$2"
                shift 2
                ;;
            -f|--file)
                file="$2"
                shift 2
                ;;
            --no-verify)
                verify=false
                shift
                ;;
            *)
                echo -e "${RED}错误: 未知导入选项 $1${NC}" >&2
                exit 1
                ;;
        esac
    done

    # 读取输入
    local input
    if [ -n "$file" ]; then
        if [ ! -f "$file" ]; then
            echo -e "${RED}错误: 文件不存在: $file${NC}" >&2
            exit 1
        fi
        input=$(cat "$file")
    else
        # 检查是否有管道输入
        if [ -t 0 ]; then
            echo -e "${BLUE}请粘贴你的curl请求，按Ctrl+D结束输入:${NC}"
            echo -e "${YELLOW}（直接在终端右键粘贴即可，不需要加引号）${NC}"
        fi
        input=$(cat)
    fi

    if [ -z "$input" ]; then
        echo -e "${RED}错误: 未读取到输入内容${NC}" >&2
        exit 1
    fi

    # 解析curl请求
    echo -e "${BLUE}正在解析curl请求...${NC}"
    parsed=$(parse_curl "$input")
    if [ $? -ne 0 ]; then
        exit 1
    fi

    IFS='|' read -r connect_sid digest csrf_token <<< "$parsed"

    # 显示提取结果
    echo -e "${GREEN}✅ 成功提取参数:${NC}"
    echo -e "  connect_sid: ${BLUE}${connect_sid:0:50}...${NC}"
    echo -e "  digest: ${BLUE}${digest:0:50}...${NC}"
    echo -e "  csrf_token: ${BLUE}$csrf_token${NC}"
    echo ""

    # 验证配置
    if [ "$verify" = true ]; then
        if ! verify_config "$connect_sid" "$digest" "$csrf_token"; then
            echo -e "${YELLOW}是否仍要保存配置？(y/N)${NC}"
            read -r confirm
            if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}已取消保存${NC}"
                exit 0
            fi
        fi
        echo ""
    fi

    # 保存配置
    save_config "$account" "$connect_sid" "$digest" "$csrf_token"
    echo -e "${GREEN}🎉 配置已成功保存到账号: $account${NC}"
    echo -e "现在可以使用以下命令查询用量:${NC}"
    echo -e "  ${BLUE}./codingplan-query.sh query -a $account${NC}"
}

# 时间戳转友好格式
format_timestamp() {
    local ts="$1"
    if command -v gdate &> /dev/null; then
        gdate -d "@$ts" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$ts"
    else
        date -r "$ts" "+%Y-%m-%d %H:%M" 2>/dev/null || echo "$ts"
    fi
}

# 计算剩余时间
format_remaining_time() {
    local ts="$1"
    local now=$(date +%s)
    local diff=$((ts - now))

    if [ $diff -le 0 ]; then
        echo "已过期"
    elif [ $diff -lt 3600 ]; then
        echo "$((diff / 60))分钟"
    elif [ $diff -lt 86400 ]; then
        echo "$((diff / 3600))小时 $(((diff % 3600) / 60))分钟"
    else
        echo "$((diff / 86400))天 $(((diff % 86400) / 3600))小时"
    fi
}

# 解析JWT获取payload
parse_jwt_payload() {
    local jwt="$1"
    local payload_part=$(echo "$jwt" | cut -d'.' -f2)

    # Base64url解码，处理补位
    local decoded=$(echo "$payload_part" | tr '_-' '/+' | fold -w4 | while read -r line; do
        len=${#line}
        if [ $len -lt 4 ]; then
            printf "%s%s\n" "$line" $(printf '=%.0s' $(seq 1 $((4 - len))))
        else
            echo "$line"
        fi
    done | tr -d '\n' | base64 -d 2>/dev/null)

    echo "$decoded"
}

# 查询用量
query_usage() {
    local account="$DEFAULT_ACCOUNT"
    local output_format="normal"

    # 解析参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--account)
                account="$2"
                shift 2
                ;;
            -j|--json)
                output_format="json"
                shift
                ;;
            -s|--short)
                output_format="short"
                shift
                ;;
            *)
                echo -e "${RED}错误: 未知查询选项 $1${NC}" >&2
                show_help >&2
                exit 1
                ;;
        esac
    done

    # 读取配置
    connect_sid=$(read_config "$account" "connect_sid")
    digest=$(read_config "$account" "digest")
    csrf_token=$(read_config "$account" "csrf_token")

    if [ -z "$connect_sid" ] || [ -z "$digest" ] || [ -z "$csrf_token" ]; then
        echo -e "${RED}错误: 账号 '$account' 的配置不完整${NC}" >&2
        echo -e "请先运行 ${BLUE}./codingplan-query.sh import${NC} 导入配置${NC}" >&2
        exit 1
    fi

    # 构造Cookie
    cookie="connect.sid=$connect_sid; digest=$digest; csrfToken=$csrf_token"

    # 发送请求
    response=$(curl -s -w "\n%{http_code}" "https://console.volcengine.com/api/top/ark/cn-beijing/2024-01-01/GetCodingPlanUsage" \
        -H "content-type: application/json" \
        -H "referer: https://console.volcengine.com/ark/region:ark+cn-beijing/openManagement?LLM=%7B%7D&action=%7B%7D&advancedActiveKey=subscribe&tab=Application" \
        -H "origin: https://console.volcengine.com" \
        -H "x-csrf-token: $csrf_token" \
        -b "$cookie" \
        --data-raw '{}')

    # 分离响应体和状态码（兼容macOS）
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | sed '$d')

    # 处理错误
    if [ "$http_code" -ne 200 ]; then
        if [ "$http_code" -eq 401 ] || [ "$http_code" -eq 403 ]; then
            echo -e "${RED}错误: 认证失败，请检查你的认证信息是否正确或已过期${NC}" >&2
            echo -e "可以重新运行 ${BLUE}./codingplan-query.sh import${NC} 更新配置${NC}" >&2
        else
            echo -e "${RED}错误: 请求失败，HTTP状态码: $http_code${NC}" >&2
        fi
        echo -e "响应内容: $body" >&2
        exit 1
    fi

    # 检查返回是否成功
    if ! echo "$body" | jq -e '.ResponseMetadata' >/dev/null 2>&1; then
        error_msg=$(echo "$body" | jq -r '.message // "未知错误"' 2>/dev/null || echo "未知错误")
        echo -e "${RED}错误: 查询失败 - $error_msg${NC}" >&2
        exit 1
    fi

    # 解析数据
    result=$(echo "$body" | jq '.Result')
    status=$(echo "$result" | jq -r '.Status')
    update_time=$(echo "$result" | jq -r '.UpdateTimestamp')
    quota_usage=$(echo "$result" | jq -c '.QuotaUsage[]')

    # 解析digest JWT获取凭证有效期
    local digest_exp_str=""
    local digest_remaining_str=""
    local digest_payload=$(parse_jwt_payload "$digest")
    if [ -n "$digest_payload" ]; then
        local digest_exp=$(echo "$digest_payload" | jq -r '.exp' 2>/dev/null || echo 0)
        if [ "$digest_exp" -gt 0 ]; then
            local now=$(date +%s)
            local digest_remaining=$((digest_exp - now))
            digest_exp_str=$(format_timestamp "$digest_exp")
            if [ $digest_remaining -gt 0 ]; then
                digest_remaining_str=$(format_remaining_time "$digest_exp")
                if [ $digest_remaining -lt 86400 ]; then # 不足1天显示黄色
                    digest_remaining_str="${YELLOW}$digest_remaining_str${NC}"
                elif [ $digest_remaining -lt 3600 ]; then # 不足1小时显示红色
                    digest_remaining_str="${RED}$digest_remaining_str${NC}"
                else
                    digest_remaining_str="${BLUE}$digest_remaining_str${NC}"
                fi
            else
                digest_remaining_str="${RED}已过期${NC}"
            fi
        fi
    fi

    # 根据格式输出
    case "$output_format" in
        "json")
            echo "$body"
            ;;
        "short")
            # 取周用量显示在状态栏
            weekly_percent=$(echo "$quota_usage" | grep '"Level":"weekly"' | jq -r '.Percent')
            weekly_percent=$(printf "%.1f" "$weekly_percent")
            echo "周用量: ${weekly_percent}%"
            ;;
        *)
            echo -e "${GREEN}📊 豆包编程助手用量查询结果 - 账号: $account${NC}"
            echo "────────────────────────────────────────"
            echo -e "状态: ${BLUE}$status${NC}"
            echo -e "最后更新: ${BLUE}$(format_timestamp "$update_time")${NC}"
            if [ -n "$digest_exp_str" ]; then
                echo -e "凭证有效期: ${BLUE}$digest_exp_str${NC} (剩余: $digest_remaining_str)"
            fi
            echo ""

            # 遍历所有用量类型
            echo "$quota_usage" | while read -r item; do
                level=$(echo "$item" | jq -r '.Level')
                percent=$(echo "$item" | jq -r '.Percent')
                reset_ts=$(echo "$item" | jq -r '.ResetTimestamp')
                remaining=$(format_remaining_time "$reset_ts")

                # 格式化百分比
                percent=$(printf "%.1f" "$percent")
                remaining_percent=$(printf "%.1f" "$(echo "100 - $percent" | bc -l)")

                # 显示名称和总配额
                local level_name=""
                local total_seconds=0
                local total_quota_str=""
                case "$level" in
                    "session")
                        level_name="会话限制"
                        total_seconds=$((5 * 3600)) # 5小时
                        total_quota_str="总配额: 5小时"
                        ;;
                    "weekly")
                        level_name="每周限制"
                        total_seconds=$((7 * 86400)) # 7天
                        total_quota_str="总配额: 每周40小时"
                        ;;
                    "monthly")
                        level_name="每月限制"
                        total_seconds=$((30 * 86400)) # 30天
                        total_quota_str="总配额: 每月160小时"
                        ;;
                    *)
                        level_name="$level"
                        total_seconds=86400 # 默认1天
                        total_quota_str=""
                        ;;
                esac

                echo -e "${YELLOW}$level_name:${NC} ${BLUE}$total_quota_str${NC}"
                echo -e "  已使用: ${YELLOW}${percent}%${NC}"
                echo -e "  剩余: ${GREEN}${remaining_percent}%${NC}"

                # 用量进度条（正向：已使用越多，■越多）
                bar_length=20
                usage_filled_length=$(echo "scale=0; $percent * $bar_length / 100" | bc)
                usage_bar=""
                for ((i=0; i<usage_filled_length; i++)); do usage_bar="${usage_bar}■"; done
                for ((i=usage_filled_length; i<bar_length; i++)); do usage_bar="${usage_bar}□"; done
                echo -e "  用量进度: $usage_bar $percent%"

                # 计算时间剩余百分比
                local now=$(date +%s)
                local time_remaining=$((reset_ts - now))
                local time_percent=0
                if [ $time_remaining -gt 0 ] && [ $total_seconds -gt 0 ]; then
                    time_percent=$(echo "scale=2; $time_remaining / $total_seconds * 100" | bc -l)
                    # 处理超过100%的情况
                    if [ $(echo "$time_percent > 100" | bc) -eq 1 ]; then
                        time_percent=100
                    fi
                fi
                time_percent=$(printf "%.1f" "$time_percent")

                # 时间进度条（反向：剩余越多，■越多）
                time_filled_length=$(echo "scale=0; $time_percent * $bar_length / 100" | bc)
                time_bar=""
                for ((i=0; i<time_filled_length; i++)); do time_bar="${time_bar}■"; done
                for ((i=time_filled_length; i<bar_length; i++)); do time_bar="${time_bar}□"; done
                echo -e "  时间进度: $time_bar $time_percent%"

                echo -e "  重置时间: ${BLUE}$(format_timestamp "$reset_ts")${NC}"
                echo -e "  剩余时间: ${BLUE}$remaining${NC}"
                echo ""
            done

            # 智能建议
            weekly_percent=$(echo "$quota_usage" | grep '"Level":"weekly"' | jq -r '.Percent')
            if [ $(echo "$weekly_percent > 90" | bc) -eq 1 ]; then
                echo -e "${RED}💡 建议: 周用量即将耗尽，请及时切换其他账号或等待重置${NC}"
            elif [ $(echo "$weekly_percent > 70" | bc) -eq 1 ]; then
                echo -e "${YELLOW}💡 建议: 周用量已使用70%以上，请注意控制使用时长${NC}"
            else
                echo -e "${GREEN}💡 建议: 用量充足，请合理使用${NC}"
            fi

            # 凭证过期提醒
            if [ -n "$digest_payload" ]; then
                local digest_exp=$(echo "$digest_payload" | jq -r '.exp' 2>/dev/null || echo 0)
                if [ "$digest_exp" -gt 0 ]; then
                    local now=$(date +%s)
                    local digest_remaining=$((digest_exp - now))
                    if [ $digest_remaining -lt 86400 ] && [ $digest_remaining -gt 0 ]; then
                        echo -e "${YELLOW}⚠️  提醒: 登录凭证还有不到1天过期，请及时更新${NC}"
                    elif [ $digest_remaining -le 0 ]; then
                        echo -e "${RED}⚠️  警告: 登录凭证已过期，请重新导入${NC}"
                    fi
                fi
            fi
            ;;
    esac
}

# 主函数
main() {
    check_dependencies
    check_config

    if [ $# -eq 0 ]; then
        # 默认运行查询
        query_usage
        exit 0
    fi

    local cmd="$1"
    shift

    case "$cmd" in
        query)
            query_usage "$@"
            ;;
        import)
            import_config "$@"
            ;;
        config)
            if [ $# -eq 0 ]; then
                echo -e "${RED}错误: 缺少config子命令${NC}" >&2
                echo -e "可用子命令: list, remove${NC}" >&2
                exit 1
            fi
            local subcmd="$1"
            shift
            case "$subcmd" in
                list)
                    list_accounts
                    ;;
                remove)
                    if [ $# -eq 0 ]; then
                        echo -e "${RED}错误: 请指定要删除的账号名称${NC}" >&2
                        exit 1
                    fi
                    remove_account "$1"
                    ;;
                *)
                    echo -e "${RED}错误: 未知config子命令: $subcmd${NC}" >&2
                    exit 1
                    ;;
            esac
            ;;
        help)
            show_help
            ;;
        version)
            show_version
            ;;
        *)
            # 兼容旧版参数，没有命令默认是query
            query_usage "$cmd" "$@"
            ;;
    esac
}

main "$@"
