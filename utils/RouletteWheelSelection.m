function choice = RouletteWheelSelection(weights)
% RouletteWheelSelection 轮盘赌选择算法（向后兼容包装器）
%
% 此函数是向后兼容包装器，实际功能已迁移到:
%   shared.operators.selection.RouletteWheelSelection
%
% 警告: 此函数已弃用，建议使用新的统一版本
%
% 语法:
%   choice = RouletteWheelSelection(weights)
%
% 输入参数:
%   weights - 权重向量，每个元素代表对应个体的选择概率权重
%
% 输出参数:
%   choice - 被选中个体的索引
%
% 使用示例:
%   weights = [10, 30, 20, 40];
%   selected = RouletteWheelSelection(weights);
%
% 新版本使用示例:
%   idx = shared.operators.selection.RouletteWheelSelection.quickSelect(weights);
%
% 版本: 2.1.0 (兼容包装器)
% 日期: 2026

    persistent warned;
    if isempty(warned) || ~warned
        warning('RouletteWheelSelection:Deprecated', ...
            ['utils/RouletteWheelSelection is deprecated. ', ...
             'Use shared.operators.selection.RouletteWheelSelection instead.']);
        warned = true;
    end

    choice = shared.operators.selection.RouletteWheelSelection.quickSelect(weights);
end
