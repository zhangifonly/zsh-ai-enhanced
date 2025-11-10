#!/Users/zhangzhen/.local/bin/izsh

# 测试 AI 自动确认功能

echo "========================================"
echo "iZsh AI 自动确认功能测试"
echo "========================================"
echo ""

# 测试 1: 基本确认（等待用户输入）
echo "=== 测试 1: 基本确认（请在 3 秒内按 Y 或等待 AI 自动选择） ==="
result=$(ai_confirm "是否继续安装？" "Y/n" 3)
echo "选择结果: $result"
echo ""

# 测试 2: 超时自动选择
echo "=== 测试 2: 超时自动选择（请等待 3 秒，不要输入） ==="
result=$(ai_confirm "是否更新配置文件？" "Y/n" 3)
echo "选择结果: $result"
echo ""

# 测试 3: 多选项
echo "=== 测试 3: 多选项确认（请等待 AI 选择） ==="
result=$(ai_confirm "选择操作模式：1)快速 2)标准 3)详细" "1/2/3" 3)
echo "选择结果: $result"
echo ""

# 测试 4: 模拟交互式程序
echo "=== 测试 4: 模拟交互式安装程序 ==="
echo "开始安装程序..."
sleep 1

result=$(ai_confirm "是否接受许可协议？" "Y/n" 3)
if [[ "$result" =~ [Yy] ]]; then
    echo "✅ 许可协议已接受"
else
    echo "❌ 安装已取消"
    exit 1
fi

result=$(ai_confirm "是否安装到默认目录？" "Y/n" 3)
if [[ "$result" =~ [Yy] ]]; then
    echo "✅ 将安装到默认目录"
else
    echo "请输入安装目录："
fi

result=$(ai_confirm "是否创建桌面快捷方式？" "Y/n" 3)
if [[ "$result" =~ [Yy] ]]; then
    echo "✅ 将创建桌面快捷方式"
fi

echo ""
echo "安装完成！"
echo ""

echo "========================================"
echo "测试完成"
echo "========================================"
echo ""
echo "说明："
echo "- ai_confirm 函数会显示 3 秒倒计时"
echo "- 用户可以随时按键选择"
echo "- 超时后 AI 自动分析并选择最佳选项"
echo "- 默认选择积极/继续的选项（如 Y、1 等）"
