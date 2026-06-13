classdef MDMTSPProblem < handle
    % MDMTSPPROBLEM 多仓库多旅行商问题类
    %
    % 将MD-MTSP（Multi-Depot Multiple Travelling Salesman Problem）整合到
    % 优化框架中的适配器类。该问题模拟物流配送、车辆路径规划等实际应用场景。
    %
    % 问题特性:
    %   - 类型: 组合优化问题（NP-hard）
    %   - 目标: 最小化所有旅行商的总路径长度
    %   - 约束: 多仓库、多旅行商、路径连续性
    %
    % 使用示例:
    %   % 创建默认问题
    %   problem = MDMTSPProblem();
    %   
    %   % 创建自定义问题
    %   problem = MDMTSPProblem('num_cities', 20, 'num_depots', 3);
    %   
    %   % 评估解
    %   x = rand(1, problem.dimension);
    %   fitness = problem.evaluate(x);
    %   
    %   % 获取路径
    %   [fitness, routes] = problem.evaluate(x);
    %
    % 来源: Multi-Depot Multiple Travelling Salesman Problem 文件夹
    % 整合版本: 1.0.0
    % 作者：RUOFENG YU
    % 日期: 2025

    properties
        id string = "MDMTSP"          % 问题ID
        name string = "多仓库多旅行商问题"  % 问题名称
        description string = "模拟物流配送场景，最小化多仓库多旅行商的总路径长度"
        
        % 问题参数
        num_cities int64 = 15         % 城市数量
        num_depots int64 = 2          % 仓库数量
        travelers_per_depot int64 = [2, 2]  % 各仓库旅行商数量
        area_size double = 200        % 区域大小
        
        % 位置数据
        locations double = []         % 所有节点坐标 (num_depots+num_cities) x 2
        depot_coords double = []      % 仓库坐标 num_depots x 2
        city_coords double = []       % 城市坐标 num_cities x 2
        
        % 预计算数据
        distance_matrix double = []   % 距离矩阵
        depot_city_dist double = []   % 仓库到城市距离
        
        % 边界（解空间）
        lowerBound double             % 下边界
        upperBound double             % 上边界
        dimension int64               % 解维度（=城市数量）
        
        % 随机种子
        random_seed int64 = 0         % 0表示不设置种子
    end

    properties (Dependent)
        total_travelers               % 总旅行商数量
        optimalValue                  % 最优值（未知）
    end

    methods
        function obj = MDMTSPProblem(varargin)
            % MDMTSPPROBLEM 构造函数
            %
            % 支持键值对参数:
            %   'num_cities' - 城市数量（默认15）
            %   'num_depots' - 仓库数量（默认2）
            %   'travelers_per_depot' - 各仓库旅行商数量（默认[2,2]）
            %   'area_size' - 区域大小（默认200）
            %   'random_seed' - 随机种子（默认0，不设置）
            %
            % 示例:
            %   problem = MDMTSPProblem('num_cities', 20, 'num_depots', 3);

            p = inputParser;
            addParameter(p, 'num_cities', 15, @isnumeric);
            addParameter(p, 'num_depots', 2, @isnumeric);
            addParameter(p, 'travelers_per_depot', [2, 2], @isvector);
            addParameter(p, 'area_size', 200, @isnumeric);
            addParameter(p, 'random_seed', 0, @isnumeric);
            addParameter(p, 'locations', [], @ismatrix);

            parse(p, varargin{:});

            obj.num_cities = int64(p.Results.num_cities);
            obj.num_depots = int64(p.Results.num_depots);
            obj.travelers_per_depot = int64(p.Results.travelers_per_depot);
            obj.area_size = double(p.Results.area_size);
            obj.random_seed = int64(p.Results.random_seed);
            obj.dimension = obj.num_cities;

            % 验证参数
            obj.validateParameters();

            % 生成或设置位置数据
            if ~isempty(p.Results.locations)
                obj.setLocationData(p.Results.locations);
            else
                obj.generateRandomLocations();
            end

            % 设置边界
            total_t = sum(obj.travelers_per_depot);
            obj.lowerBound = 0;
            obj.upperBound = total_t;
        end

        function validateParameters(obj)
            % validateParameters 验证问题参数的合法性

            if obj.num_cities < 2
                error('MDMTSPProblem:InvalidParameter', ...
                    '城市数量必须 >= 2');
            end

            if obj.num_depots < 1
                error('MDMTSPProblem:InvalidParameter', ...
                    '仓库数量必须 >= 1');
            end

            if length(obj.travelers_per_depot) ~= obj.num_depots
                error('MDMTSPProblem:InvalidParameter', ...
                    'travelers_per_depot长度必须等于num_depots');
            end

            if any(obj.travelers_per_depot < 1)
                error('MDMTSPProblem:InvalidParameter', ...
                    '每个仓库的旅行商数量必须 >= 1');
            end

            if obj.area_size <= 0
                error('MDMTSPProblem:InvalidParameter', ...
                    '区域大小必须 > 0');
            end
        end

        function generateRandomLocations(obj)
            % generateRandomLocations 生成随机位置数据

            if obj.random_seed > 0
                rng(obj.random_seed);
            else
                rng('shuffle');
            end

            obj.depot_coords = rand(obj.num_depots, 2) * obj.area_size;
            obj.city_coords = rand(obj.num_cities, 2) * obj.area_size;
            obj.locations = [obj.depot_coords; obj.city_coords];

            obj.precomputeDistances();
        end

        function setLocationData(obj, locations)
            % setLocationData 设置位置数据
            %
            % 输入:
            %   locations - 所有节点坐标矩阵，前num_depots行为仓库，其余为城市

            expected_rows = obj.num_depots + obj.num_cities;
            if size(locations, 1) ~= expected_rows
                error('MDMTSPProblem:InvalidData', ...
                    'locations应有%d行，实际%d行', expected_rows, size(locations, 1));
            end

            obj.locations = locations;
            obj.depot_coords = locations(1:obj.num_depots, :);
            obj.city_coords = locations(obj.num_depots+1:end, :);

            obj.precomputeDistances();
        end

        function precomputeDistances(obj)
            % precomputeDistances 预计算距离矩阵

            obj.distance_matrix = pdist2(obj.locations, obj.locations);
            obj.depot_city_dist = pdist2(obj.depot_coords, obj.city_coords);
        end

        function fitness = evaluate(obj, solution)
            % evaluate 评估解的适应度
            %
            % 输入:
            %   solution - 解向量，长度为num_cities，值域[0, total_travelers]
            %
            % 输出:
            %   fitness - 适应度值（总路径长度）
            %
            % 示例:
            %   x = rand(1, problem.dimension) * problem.upperBound;
            %   fitness = problem.evaluate(x);

            [fitness, ~] = obj.computeFitnessAndRoutes(solution);
        end

        function [fitness, routes, assignment] = evaluateWithRoutes(obj, solution)
            % evaluateWithRoutes 评估解并返回路径
            %
            % 输入:
            %   solution - 解向量
            %
            % 输出:
            %   fitness - 适应度值
            %   routes - 各旅行商的路径（元胞数组）
            %   assignment - 城市到旅行商的分配

            [fitness, routes, assignment] = obj.computeFitnessAndRoutes(solution);
        end

        function [fitness, routes, assignment] = computeFitnessAndRoutes(obj, solution)
            % computeFitnessAndRoutes 计算适应度和路径

            num_travelers = sum(obj.travelers_per_depot);
            
            % 解码：将连续值转换为旅行商分配
            assignment = ceil(solution * num_travelers / obj.upperBound);
            assignment = min(max(assignment, 1), num_travelers);

            total_distance = 0;
            routes = cell(1, num_travelers);

            for traveler_idx = 1:num_travelers
                % 找到对应的仓库
                depot_idx = obj.getDepotForTraveler(traveler_idx);

                % 获取分配给该旅行商的城市
                cities = find(assignment == traveler_idx);

                if isempty(cities)
                    routes{traveler_idx} = [];
                    continue;
                end

                % 按照解的小数部分排序确定访问顺序
                decimals = mod(solution(cities), 1);
                [~, order] = sort(decimals, 'descend');
                sorted_cities = cities(order);

                % 构建路径：仓库 -> 城市 -> 仓库
                route = [depot_idx, sorted_cities(:)' + obj.num_depots, depot_idx];

                % 2-opt局部优化
                route = obj.twoOptOptimize(route);

                % 计算路径长度
                route_length = obj.calculateRouteLength(route);
                total_distance = total_distance + route_length;

                routes{traveler_idx} = route;
            end

            fitness = total_distance;
        end

        function depot_idx = getDepotForTraveler(obj, traveler_idx)
            % getDepotForTraveler 获取旅行商对应的仓库索引

            cumulative = 0;
            for d = 1:obj.num_depots
                if traveler_idx <= cumulative + obj.travelers_per_depot(d)
                    depot_idx = d;
                    return;
                end
                cumulative = cumulative + obj.travelers_per_depot(d);
            end
            depot_idx = obj.num_depots;
        end

        function route = twoOptOptimize(obj, route)
            % twoOptOptimize 2-opt局部优化
            %
            % 输入:
            %   route - 原始路径
            %
            % 输出:
            %   route - 优化后的路径

            improved = true;
            n = length(route);
            best_cost = obj.calculateRouteLength(route);

            while improved
                improved = false;
                for i = 2:n-2
                    for j = i+1:n-1
                        new_route = [route(1:i-1), flip(route(i:j)), route(j+1:end)];
                        new_cost = obj.calculateRouteLength(new_route);
                        if new_cost < best_cost
                            route = new_route;
                            best_cost = new_cost;
                            improved = true;
                            break;
                        end
                    end
                    if improved
                        break;
                    end
                end
            end
        end

        function cost = calculateRouteLength(obj, route)
            % calculateRouteLength 计算路径总长度
            %
            % 输入:
            %   route - 路径节点索引向量
            %
            % 输出:
            %   cost - 路径总长度

            cost = 0;
            for i = 1:length(route)-1
                cost = cost + obj.distance_matrix(route(i), route(i+1));
            end
        end

        function is_valid = validateSolution(obj, solution)
            % validateSolution 验证解的合法性
            %
            % 输入:
            %   solution - 解向量
            %
            % 输出:
            %   is_valid - 是否有效

            if length(solution) ~= obj.dimension
                is_valid = false;
                return;
            end

            if any(solution < obj.lowerBound) || any(solution > obj.upperBound)
                is_valid = false;
                return;
            end

            is_valid = true;
        end

        function info = getProblemInfo(obj)
            % getProblemInfo 获取问题信息
            %
            % 输出:
            %   info - 问题信息结构体

            info = struct();
            info.id = obj.id;
            info.name = obj.name;
            info.description = obj.description;
            info.type = 'application';
            info.subtype = 'MDMTSP';
            info.dimension = obj.dimension;
            info.lowerBound = obj.lowerBound;
            info.upperBound = obj.upperBound;
            info.num_cities = obj.num_cities;
            info.num_depots = obj.num_depots;
            info.travelers_per_depot = obj.travelers_per_depot;
            info.total_travelers = obj.total_travelers;
            info.area_size = obj.area_size;
        end
    end

    methods (Static)
        function problem = createFromConfig(config)
            % createFromConfig 从配置创建问题实例
            %
            % 输入:
            %   config - 配置结构体，包含：
            %       .num_cities - 城市数量
            %       .num_depots - 仓库数量
            %       .travelers_per_depot - 各仓库旅行商数量
            %       .area_size - 区域大小
            %       .seed - 随机种子
            %
            % 输出:
            %   problem - MDMTSPProblem实例

            if nargin < 1
                config = struct();
            end

            if isfield(config, 'seed')
                seed = config.seed;
            else
                seed = 0;
            end

            problem = MDMTSPProblem(...
                'num_cities', getfield_default(config, 'num_cities', 15), ...
                'num_depots', getfield_default(config, 'num_depots', 2), ...
                'travelers_per_depot', getfield_default(config, 'travelers_per_depot', [2, 2]), ...
                'area_size', getfield_default(config, 'area_size', 200), ...
                'random_seed', seed);
        end

        function configs = getStandardConfigs()
            % getStandardConfigs 获取标准测试配置
            %
            % 输出:
            %   configs - 配置结构体数组

            configs = [
                struct('name', '小规模', 'num_cities', 10, 'num_depots', 2, 'travelers_per_depot', [1, 1], 'area_size', 100)
                struct('name', '中规模', 'num_cities', 15, 'num_depots', 2, 'travelers_per_depot', [2, 2], 'area_size', 200)
                struct('name', '大规模', 'num_cities', 25, 'num_depots', 3, 'travelers_per_depot', [2, 2, 2], 'area_size', 300)
                struct('name', '超大规模', 'num_cities', 50, 'num_depots', 4, 'travelers_per_depot', [3, 3, 3, 3], 'area_size', 500)
            ];
        end
    end

    methods
        function t = get.total_travelers(obj)
            t = sum(obj.travelers_per_depot);
        end

        function val = get.optimalValue(obj)
            val = 0;  % MDMTSP最优值取决于具体实例，无法预先确定
        end
    end
end

function val = getfield_default(s, field, default)
    % getfield_default 安全获取结构体字段
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
