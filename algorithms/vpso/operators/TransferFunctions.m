classdef TransferFunctions < handle
    % TransferFunctions 传递函数集合
    %
    % 提供二进制PSO中常用的传递函数，用于将连续速度转换为
    % 二进制位置更新的概率。
    %
    % 传递函数类型:
    %   - S形 (S-shaped): S1-S4，使用sigmoid变体
    %   - V形 (V-shaped): V1-V4，使用tanh/erf等变体
    %
    % 更新策略:
    %   - S形: 若 rand < T(v)，则 x_new = 1
    %   - V形: 若 rand < T(v)，则 x_new = ~x_old (翻转)
    %
    % 参考文献:
    %   S. Mirjalili and A. Lewis
    %   "S-shaped versus V-shaped transfer functions for binary
    %    Particle Swarm Optimization"
    %   Swarm and Evolutionary Computation, 2013
    %
    % 使用示例:
    %   s = TransferFunctions.V4(velocity);
    %   newPos = TransferFunctions.applyVTransfer(velocity, oldPos, s);
    %
    % 版本: 2.0.0
    % 日期: 2025

    methods (Static)
        %% S形传递函数 (S-shaped Transfer Functions)
        function s = S1(v)
            % S1 Sigmoid-1传递函数
            % s = 1 / (1 + exp(-2*v))
            s = 1 ./ (1 + exp(-2 * v));
        end

        function s = S2(v)
            % S2 Sigmoid-2传递函数
            % s = 1 / (1 + exp(-v))
            s = 1 ./ (1 + exp(-v));
        end

        function s = S3(v)
            % S3 Sigmoid-3传递函数
            % s = 1 / (1 + exp(-v/2))
            s = 1 ./ (1 + exp(-v / 2));
        end

        function s = S4(v)
            % S4 Sigmoid-4传递函数
            % s = 1 / (1 + exp(-v/3))
            s = 1 ./ (1 + exp(-v / 3));
        end

        %% V形传递函数 (V-shaped Transfer Functions)
        function s = V1(v)
            % V1 Error Function传递函数
            % s = |erf(sqrt(pi)/2 * v)|
            s = abs(erf((sqrt(pi) / 2) * v));
        end

        function s = V2(v)
            % V2 Hyperbolic Tangent传递函数
            % s = |tanh(v)|
            s = abs(tanh(v));
        end

        function s = V3(v)
            % V3 Algebraic传递函数
            % s = |v / sqrt(1 + v^2)|
            s = abs(v ./ sqrt(1 + v.^2));
        end

        function s = V4(v)
            % V4 Arctangent传递函数
            % s = |2/pi * atan(pi/2 * v)|
            s = abs((2 / pi) * atan((pi / 2) * v));
        end

        %% 应用传递函数
        function newPos = applySTransfer(v, oldPos, s)
            % applySTransfer 应用S形传递函数更新位置
            %
            % S形策略: 以概率s将位置设为1
            %
            % 输入参数:
            %   v - 速度值
            %   oldPos - 旧位置 (未使用)
            %   s - 传递函数值 (概率)
            %
            % 输出参数:
            %   newPos - 新位置 (0或1)

            if rand() < s
                newPos = 1;
            else
                newPos = 0;
            end
        end

        function newPos = applyVTransfer(v, oldPos, s)
            % applyVTransfer 应用V形传递函数更新位置
            %
            % V形策略: 以概率s翻转位置
            %
            % 输入参数:
            %   v - 速度值 (未使用)
            %   oldPos - 旧位置
            %   s - 传递函数值 (概率)
            %
            % 输出参数:
            %   newPos - 新位置 (0或1)

            if rand() < s
                newPos = ~oldPos;
            else
                newPos = oldPos;
            end
        end

        %% 批量应用传递函数
        function newPos = applySTransferBatch(v, oldPos, s)
            % applySTransferBatch 批量应用S形传递函数
            %
            % 输入参数:
            %   v - 速度向量
            %   oldPos - 旧位置向量 (未使用)
            %   s - 传递函数值向量 (概率)
            %
            % 输出参数:
            %   newPos - 新位置向量 (0和1)

            r = rand(size(v));
            newPos = r < s;
        end

        function newPos = applyVTransferBatch(v, oldPos, s)
            % applyVTransferBatch 批量应用V形传递函数
            %
            % 输入参数:
            %   v - 速度向量 (未使用)
            %   oldPos - 旧位置向量
            %   s - 传递函数值向量 (概率)
            %
            % 输出参数:
            %   newPos - 新位置向量 (0和1)

            r = rand(size(v));
            flip = r < s;
            newPos = oldPos;
            newPos(flip) = ~oldPos(flip);
        end

        %% 获取传递函数句柄
        function handle = getFunction(type)
            % getFunction 根据类型获取传递函数句柄
            %
            % 输入参数:
            %   type - 传递函数类型 ('S1'-'S4', 'V1'-'V4')
            %
            % 输出参数:
            %   handle - 传递函数句柄

            switch upper(type)
                case 'S1'
                    handle = @TransferFunctions.S1;
                case 'S2'
                    handle = @TransferFunctions.S2;
                case 'S3'
                    handle = @TransferFunctions.S3;
                case 'S4'
                    handle = @TransferFunctions.S4;
                case 'V1'
                    handle = @TransferFunctions.V1;
                case 'V2'
                    handle = @TransferFunctions.V2;
                case 'V3'
                    handle = @TransferFunctions.V3;
                case 'V4'
                    handle = @TransferFunctions.V4;
                otherwise
                    error('TransferFunctions:InvalidType', ...
                        'Unknown transfer function type: %s', type);
            end
        end

        function isVshaped = isVType(type)
            % isVType 判断是否为V形传递函数
            %
            % 输入参数:
            %   type - 传递函数类型
            %
            % 输出参数:
            %   isVshaped - 是否为V形

            isVshaped = startsWith(upper(type), 'V');
        end
    end
end
