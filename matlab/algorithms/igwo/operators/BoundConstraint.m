classdef BoundConstraint < handle
    % BoundConstraint 边界约束处理器
    %
    % 实现L-SHADE风格的中点修复策略。当个体超出边界时，将其重置到
    % 当前位置和边界的中点，而非简单截断。
    %
    % 使用示例:
    %   constrainer = BoundConstraint();
    %   positions = rand(30, 10) * 200 - 100;  % 可能超出边界
    %   lb = -100; ub = 100;
    %   positions = constrainer.apply(positions, lb, ub);
    %
    % 参考文献:
    %   L-SHADE算法的边界处理策略
    %
    % 原始来源: I-GWO算法
    % 整合版本: 2.0.0
    % 日期: 2025

    methods
        function obj = BoundConstraint()
            % BoundConstraint 构造函数
            % 无参数
        end

        function vi = apply(obj, vi, pop, lu)
            % apply 应用边界约束
            %
            % 输入参数:
            %   vi  - 待检查的位置矩阵 (NP x D)
            %   pop - 当前种群位置矩阵 (NP x D)，用于中点计算
            %   lu  - 边界矩阵 (2 x D)，第一行为下界，第二行为上界
            %
            % 输出参数:
            %   vi  - 修复后的位置矩阵
            %
            % 算法:
            %   如果 vi[i,j] < lb[j], 则 vi[i,j] = (pop[i,j] + lb[j]) / 2
            %   如果 vi[i,j] > ub[j], 则 vi[i,j] = (pop[i,j] + ub[j]) / 2

            [NP, D] = size(pop);

            % 检查下边界
            xl = repmat(lu(1, :), NP, 1);
            pos = vi < xl;
            vi(pos) = (pop(pos) + xl(pos)) / 2;

            % 检查上边界
            xu = repmat(lu(2, :), NP, 1);
            pos = vi > xu;
            vi(pos) = (pop(pos) + xu(pos)) / 2;
        end

        function vi = applyScalar(obj, vi, pop, lb, ub)
            % applyScalar 应用边界约束 (标量边界版本)
            %
            % 输入参数:
            %   vi  - 待检查的位置矩阵 (NP x D)
            %   pop - 当前种群位置矩阵 (NP x D)
            %   lb  - 下边界 (标量)
            %   ub  - 上边界 (标量)
            %
            % 输出参数:
            %   vi  - 修复后的位置矩阵

            % 转换标量边界为矩阵格式
            D = size(pop, 2);
            lu = [repmat(lb, 1, D); repmat(ub, 1, D)];

            vi = obj.apply(vi, pop, lu);
        end
    end
end
