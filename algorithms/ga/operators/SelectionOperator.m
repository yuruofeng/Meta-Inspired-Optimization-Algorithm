classdef (Abstract) SelectionOperator < handle
    % SelectionOperator 选择算子抽象基类
    %
    % 定义遗传算法选择算子的统一接口。所有具体选择算子
    % (锦标赛、轮盘赌、排序选择等)必须继承此类。
    %
    % 参考规范: metaheuristic_spec.md §3.2
    %
    % 使用示例:
    %   classdef TournamentSelection < SelectionOperator
    %       methods
    %           function indices = select(obj, population, fitness, n)
    %               % 实现具体选择逻辑
    %           end
    %       end
    %   end
    %
    % 版本: 2.0.0
    % 日期: 2025

    methods (Abstract)
        indices = select(obj, population, fitness, n)
        % select 执行选择操作
        %
        % 输入参数:
        %   population - 种群矩阵 (N x Dim)
        %   fitness - 适应度向量 (N x 1)，值越小表示越优（最小化）
        %   n - 需要选择的个体数量
        %
        % 输出参数:
        %   indices - 被选中个体的索引数组 (n x 1)
    end

    methods
        function selectedPop = selectPopulation(obj, population, fitness, n)
            % selectPopulation 选择并返回个体
            %
            % 输入参数:
            %   population - 种群矩阵 (N x Dim)
            %   fitness - 适应度向量 (N x 1)
            %   n - 需要选择的个体数量
            %
            % 输出参数:
            %   selectedPop - 被选中的种群矩阵 (n x Dim)

            indices = obj.select(population, fitness, n);
            selectedPop = population(indices, :);
        end
    end
end
