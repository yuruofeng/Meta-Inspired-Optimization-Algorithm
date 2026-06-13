classdef UniformMutation < handle
    % UniformMutation 均匀变异算子
    %
    % 用于二进制/特征选择问题的变异操作。采用自适应变异率，
    % 随迭代进行逐渐降低变异概率。
    %
    % 算法原理:
    %   1. 计算变异概率阈值 = currentIter / maxIter
    %   2. 生成随机数 r
    %   3. 对 r >= 阈值的位置，随机设置新值 (0 或 1)
    %   4. 随迭代进行，阈值增大，变异减少（开发阶段）
    %
    % 参考文献:
    %   M. Mafarja and S. Mirjalili
    %   "Hybrid Whale Optimization Algorithm with Simulated Annealing
    %    for Feature Selection"
    %   Neurocomputing, 2017
    %
    % 使用示例:
    %   mutator = UniformMutation();
    %   mutated = mutator.mute(solution, currentIter, maxIter);
    %
    % 原始作者: Majdi Mafarja, Seyedali Mirjalili
    % 重构版本: 2.0.0
    % 日期: 2025

    methods
        function obj = UniformMutation()
            % UniformMutation 构造函数
        end

        function mutated = mute(obj, solution, currentIter, maxIter)
            % mute 执行均匀变异
            %
            % 输入参数:
            %   solution - 原始二进制解向量 (1 x Dim) 或 (Dim x 1)
            %   currentIter - 当前迭代次数
            %   maxIter - 最大迭代次数
            %
            % 输出参数:
            %   mutated - 变异后的二进制解向量
            %
            % 变异策略:
            %   - 迭代初期: 高变异率，增加探索
            %   - 迭代后期: 低变异率，加强开发

            dim = length(solution);
            r = rand(1, dim);

            % 变异掩码: r >= threshold 的位置将被变异
            % threshold 随迭代增大，导致更少位置被变异
            threshold = currentIter / maxIter;
            mutationMask = r >= threshold;

            mutated = solution;
            % 对变异位置设置随机二进制值
            mutated(mutationMask) = rand(sum(mutationMask(:)), 1) > 0.5;
        end

        function mutated = muteWithRate(obj, solution, mutationRate)
            % muteWithRate 使用固定变异率执行变异
            %
            % 输入参数:
            %   solution - 原始二进制解向量
            %   mutationRate - 固定变异率 [0, 1]
            %
            % 输出参数:
            %   mutated - 变异后的二进制解向量

            dim = length(solution);
            r = rand(1, dim);
            mutationMask = r < mutationRate;

            mutated = solution;
            mutated(mutationMask) = rand(sum(mutationMask(:)), 1) > 0.5;
        end
    end

    methods (Static)
        function mutated = muteStatic(solution, currentIter, maxIter)
            % muteStatic 静态方法版本的变异操作
            %
            % 输入参数:
            %   solution - 原始二进制解向量
            %   currentIter - 当前迭代次数
            %   maxIter - 最大迭代次数
            %
            % 输出参数:
            %   mutated - 变异后的二进制解向量

            dim = length(solution);
            r = rand(1, dim);
            threshold = currentIter / maxIter;
            mutationMask = r >= threshold;

            mutated = solution;
            mutated(mutationMask) = rand(sum(mutationMask(:)), 1) > 0.5;
        end
    end
end
