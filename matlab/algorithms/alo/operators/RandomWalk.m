classdef RandomWalk < handle
    % RandomWalk 蚁狮周围的随机游走算子
    %
    % 实现ALO算法中的自适应随机游走机制，包括:
    %   - 边界收缩 (adaptive I ratio)
    %   - 蚁狮周围边界调整
    %   - 随机游走生成和归一化
    %
    % 参考文献:
    %   S. Mirjalili, "The Ant Lion Optimizer"
    %   Advances in Engineering Software, 2015
    %   DOI: 10.1016/j.advengsoft.2015.01.010
    %
    % 使用示例:
    %   walker = RandomWalk();
    %   RW = walker.walk(dim, max_iter, lb, ub, antlion_pos, current_iter);
    %
    % 原始作者: Seyedali Mirjalili
    % 整合版本: 2.0.0
    % 日期: 2025

    methods
        function obj = RandomWalk()
            % RandomWalk 构造函数
            % 无参数
        end

        function RWs = walk(obj, Dim, max_iter, lb, ub, antlion, current_iter)
            % walk 执行随机游走
            %
            % 输入参数:
            %   Dim          - 问题维度
            %   max_iter     - 最大迭代次数
            %   lb           - 下边界 (标量或向量)
            %   ub           - 上边界 (标量或向量)
            %   antlion      - 蚁狮位置 (1 x Dim)
            %   current_iter - 当前迭代次数
            %
            % 输出参数:
            %   RWs - 随机游走矩阵 (max_iter x Dim)
            %
            % 算法步骤:
            %   1. 计算自适应 I ratio (Equation 2.10-2.11)
            %   2. 收缩边界围绕蚁狮 (Equation 2.8-2.9)
            %   3. 生成随机游走 (Equation 2.1)
            %   4. 归一化到边界 (Equation 2.7)

            % 处理标量边界
            if numel(lb) == 1
                lb = ones(1, Dim) * lb;
                ub = ones(1, Dim) * ub;
            end

            % 确保边界是行向量
            lb = lb(:)';
            ub = ub(:)';

            % 计算自适应 I ratio (Equation 2.10-2.11)
            I = obj.calculateIRatio(current_iter, max_iter);

            % 收缩边界 (Equation 2.10-2.11)
            lb = lb / I;
            ub = ub / I;

            % 围绕蚁狮调整边界 (Equation 2.8-2.9)
            if rand < 0.5
                lb = lb + antlion;
            else
                lb = -lb + antlion;
            end

            if rand >= 0.5
                ub = ub + antlion;
            else
                ub = -ub + antlion;
            end

            % 生成随机游走并归一化
            RWs = zeros(max_iter, Dim);
            for i = 1:Dim
                % 生成随机游走 (Equation 2.1)
                X = [0, cumsum(2 * (rand(max_iter, 1) > 0.5) - 1)'];

                % 归一化到边界 [lb(i), ub(i)] (Equation 2.7)
                a = min(X);
                b = max(X);
                c = lb(i);
                d = ub(i);

                X_norm = ((X - a) .* (d - c)) ./ (b - a) + c;
                RWs(:, i) = X_norm;
            end
        end

        function I = calculateIRatio(obj, current_iter, max_iter)
            % calculateIRatio 计算自适应I比率
            %
            % 输入参数:
            %   current_iter - 当前迭代次数
            %   max_iter     - 最大迭代次数
            %
            % 输出参数:
            %   I - 自适应比率
            %
            % 说明:
            %   随着迭代进行，I值逐渐增大，导致边界收缩加剧，
            %   从而增强开发能力

            ratio = current_iter / max_iter;

            if ratio > 0.95
                I = 1 + 1000000 * ratio;
            elseif ratio > 0.9
                I = 1 + 100000 * ratio;
            elseif ratio > 0.75
                I = 1 + 10000 * ratio;
            elseif ratio > 0.5
                I = 1 + 1000 * ratio;
            elseif ratio > 0.1
                I = 1 + 100 * ratio;
            else
                I = 1;
            end
        end
    end
end
