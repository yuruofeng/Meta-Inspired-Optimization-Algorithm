function X = Initialization(SearchAgents_no, dim, ub, lb)
    % Initialization 种群初始化函数
    %
    % 在指定的搜索空间边界内创建初始随机种群。支持统一边界和
    % 每个变量独立边界两种模式。
    %
    % 符合 metaheuristic_spec.md §4.1 规范。
    %
    % 语法:
    %   X = Initialization(SearchAgents_no, dim, ub, lb)
    %
    % 输入参数:
    %   SearchAgents_no - 搜索代理（个体）数量 (正整数)
    %   dim            - 问题维度 (正整数)
    %   ub             - 上边界 (标量或 1 x dim 向量)
    %   lb             - 下边界 (标量或 1 x dim 向量)
    %
    % 输出参数:
    %   X              - 初始种群矩阵 (SearchAgents_no x dim)
    %
    % 边界处理:
    %   - 如果 ub 和 lb 是标量，所有维度使用相同的边界
    %   - 如果 ub 和 lb 是向量，每个维度使用对应的边界
    %
    % 示例:
    %   % 所有变量统一边界 [-100, 100]
    %   pop = Initialization(50, 30, 100, -100);
    %
    %   % 每个变量独立边界
    %   lb = [-100, -10, -1];
    %   ub = [100, 10, 1];
    %   pop = Initialization(50, 3, ub, lb);
    %
    % 性能考虑:
    %   - 使用矩阵化操作替代显式循环 (规范 §4.1)
    %   - 边界数为1时使用向量化初始化
    %   - 边界数>1时逐维度初始化
    %
    % 原始来源:
    %   - Ant Lion Optimizer (ALO) by Seyedali Mirjalili
    %   - Grey Wolf Optimizer (GWO) by Seyedali Mirjalili
    %   - Improved Grey Wolf Optimizer (I-GWO) by M. H. Nadimi-Shahraki
    %
    % 合并来源:
    %   - ALO/ALO/initialization.m
    %   - GWO/GWO/initialization.m
    %   - I-GWO/I-GWO/initialization.m
    %   - Ant Lion Optimizer Toolbox/.../initialization.m
    %   - Grey Wolf Optimizer Toolbox/.../initialization.m
    %
    % 版本: 2.0.0 (统一版本)
    % 日期: 2025
    % 作者：RUOFENG YU

    % 输入验证
    validateattributes(SearchAgents_no, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, 'Initialization', 'SearchAgents_no');
    validateattributes(dim, {'numeric'}, ...
        {'scalar', 'integer', 'positive'}, 'Initialization', 'dim');

    % 确保边界是行向量
    ub = ub(:)';
    lb = lb(:)';

    % 边界数量
    Boundary_no = size(ub, 2);

    % 预分配种群矩阵 (规范 §4.3)
    X = zeros(SearchAgents_no, dim);

    % 情况1: 所有变量使用相同的边界 (标量边界)
    if Boundary_no == 1
        X = rand(SearchAgents_no, dim) .* (ub - lb) + lb;
    end

    % 情况2: 每个变量有独立的边界 (向量边界)
    if Boundary_no > 1
        % 验证边界维度
        if Boundary_no ~= dim
            error('Initialization:DimensionMismatch', ...
                'Boundary dimensions (%d) must match problem dimension (%d)', ...
                Boundary_no, dim);
        end

        for i = 1:dim
            ub_i = ub(i);
            lb_i = lb(i);
            X(:, i) = rand(SearchAgents_no, 1) .* (ub_i - lb_i) + lb_i;
        end
    end
end
