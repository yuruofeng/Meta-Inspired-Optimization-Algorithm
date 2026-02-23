classdef UniformCrossover < handle
    % UniformCrossover 统一的均匀交叉实现
    %
    % 融合了两个版本的优点：
    %   1. 支持生成单个或两个子代
    %   2. 支持静态方法调用
    %   3. 可配置的混合概率
    %   4. 完善的参数验证
    %
    % 使用示例:
    %   % 对象式调用 - 生成两个子代
    %   crossover = UniformCrossover('mixRate', 0.5);
    %   [child1, child2] = crossover.cross(parent1, parent2);
    %
    %   % 对象式调用 - 生成单个子代
    %   crossover = UniformCrossover(0.5);
    %   offspring = crossover.crossOne(parent1, parent2);
    %
    %   % 静态方法调用
    %   offspring = UniformCrossover.quickCross(parent1, parent2);
    %
    % 版本: 3.0.0 (统一版本)
    % 日期: 2026

    properties
        mixRate double = 0.5  % 从parent1取基因的概率
    end

    methods
        function obj = UniformCrossover(varargin)
            % UniformCrossover 构造函数
            %
            % 输入参数 (可选):
            %   mixRate - 从parent1取基因的概率 (默认: 0.5)
            %             值范围: [0, 1]
            %
            % 或使用名称-值对:
            %   'mixRate', value - 混合概率
            %
            % 使用示例:
            %   crossover = UniformCrossover();
            %   crossover = UniformCrossover(0.7);
            %   crossover = UniformCrossover('mixRate', 0.7);

            % 支持旧版单参数构造
            if nargin == 1 && isnumeric(varargin{1})
                rate = varargin{1};
                if rate < 0 || rate > 1
                    error('UniformCrossover:InvalidParam', ...
                        'mixRate must be in [0, 1]');
                end
                obj.mixRate = rate;
            else
                % 支持名称-值对构造
                for i = 1:2:length(varargin)
                    if strcmpi(varargin{i}, 'mixRate')
                        rate = varargin{i+1};
                        if rate < 0 || rate > 1
                            error('UniformCrossover:InvalidParam', ...
                                'mixRate must be in [0, 1]');
                        end
                        obj.mixRate = rate;
                    end
                end
            end
        end

        function varargout = cross(obj, parent1, parent2)
            % cross 执行均匀交叉（支持生成一个或两个子代）
            %
            % 输入参数:
            %   parent1 - 第一个父代 (1 x Dim)
            %   parent2 - 第二个父代 (1 x Dim)
            %
            % 输出参数:
            %   [offspring1, offspring2] - 两个子代 (推荐)
            %   offspring - 单个子代 (兼容模式)
            %
            % 注意:
            %   返回值数量取决于调用时的输出参数数量
            %   [child1, child2] = cross(...) -> 返回两个子代
            %   child = cross(...) -> 返回单个子代

            % 生成混合掩码
            mask = rand(size(parent1)) < obj.mixRate;

            % 生成第一个子代
            offspring1 = parent1;
            offspring1(~mask) = parent2(~mask);

            % 根据输出参数数量决定返回方式
            if nargout == 1
                % 兼容模式：只返回单个子代
                varargout{1} = offspring1;
            else
                % 推荐模式：返回两个子代
                offspring2 = parent2;
                offspring2(~mask) = parent1(~mask);
                varargout{1} = offspring1;
                varargout{2} = offspring2;
            end
        end

        function offspring = crossOne(obj, parent1, parent2)
            % crossOne 生成单个子代
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring - 生成的子代解向量

            r = rand(size(parent1)) < obj.mixRate;
            offspring = parent1;
            offspring(~r) = parent2(~r);
        end

        function [offspring1, offspring2] = crossTwo(obj, parent1, parent2)
            % crossTwo 生成两个子代
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring1 - 第一个子代
            %   offspring2 - 第二个子代

            r = rand(size(parent1)) < obj.mixRate;

            offspring1 = parent1;
            offspring1(~r) = parent2(~r);

            offspring2 = parent2;
            offspring2(~r) = parent1(~r);
        end
    end

    methods (Static)
        function offspring = quickCross(parent1, parent2)
            % quickCross 静态方法版本的交叉操作
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring - 生成的子代解向量
            %
            % 使用示例:
            %   offspring = UniformCrossover.quickCross(parent1, parent2);

            r = rand(size(parent1)) < 0.5;
            offspring = parent1;
            offspring(~r) = parent2(~r);
        end

        function [offspring1, offspring2] = quickCrossTwo(parent1, parent2)
            % quickCrossTwo 静态方法版本，生成两个子代
            %
            % 输入参数:
            %   parent1 - 第一个父代解向量
            %   parent2 - 第二个父代解向量
            %
            % 输出参数:
            %   offspring1 - 第一个子代
            %   offspring2 - 第二个子代

            r = rand(size(parent1)) < 0.5;

            offspring1 = parent1;
            offspring1(~r) = parent2(~r);

            offspring2 = parent2;
            offspring2(~r) = parent1(~r);
        end
    end
end
