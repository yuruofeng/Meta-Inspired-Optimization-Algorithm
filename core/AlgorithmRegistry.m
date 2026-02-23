classdef AlgorithmRegistry < handle
    % AlgorithmRegistry 算法注册表
    %
    % 采用注册表模式管理所有算法实现。新算法只需在注册表中注册，
    % 无需修改核心代码，实现开闭原则 (OCP)。
    %
    % 符合 metaheuristic_spec.md §3.1 规范。
    %
    % 使用示例:
    %   % 注册新算法
    %   AlgorithmRegistry.register('GWO', '1.0.0', @GWO);
    %
    %   % 获取算法类
    %   algClass = AlgorithmRegistry.getAlgorithm('GWO');
    %   algorithm = algClass(config);
    %
    %   % 列出所有算法
    %   algorithms = AlgorithmRegistry.listAlgorithms();
    %
    % 作者: 元启发式算法工程规范委员会
    % 版本: 1.0.0
    % 日期: 2025

    properties (Constant, Access = private)
        registry containers.Map = containers.Map()
    end

    methods (Static)
        function register(name, version, algorithmClass)
            % register 注册算法
            %
            % 输入参数:
            %   name - 算法名称 (字符串，如 'GWO', 'ALO')
            %   version - 版本号 (字符串，如 '1.0.0')
            %   algorithmClass - 算法类构造函数句柄 (如 @GWO)
            %
            % 示例:
            %   AlgorithmRegistry.register('whale_optimization', '1.0.0', @WhaleOptimizationAlgorithm);

            key = sprintf('%s:%s', name, version);

            % 验证算法类
            if ~isa(algorithmClass, 'function_handle')
                error('AlgorithmRegistry:InvalidClass', ...
                    'algorithmClass must be a function handle');
            end

            % 检查是否已存在
            if isKey(AlgorithmRegistry.registry, key)

                warning('AlgorithmRegistry:AlreadyExists', ...
                    'Algorithm %s version %s already registered. Overwriting.', ...
                    name, version);
            end

            AlgorithmRegistry.registry(key) = algorithmClass;
        end

        function algorithmClass = getAlgorithm(name, varargin)
            % getAlgorithm 获取算法类
            %
            % 输入参数:
            %   name - 算法名称
            %   version - (可选) 版本号，不指定则返回最新版本
            %
            % 输出参数:
            %   algorithmClass - 算法类构造函数句柄
            %
            % 异常:
            %   AlgorithmNotFoundError - 算法不存在时抛出
            %
            % 示例:
            %   algClass = AlgorithmRegistry.getAlgorithm('GWO');
            %   algClass = AlgorithmRegistry.getAlgorithm('GWO', '1.0.0');

            if nargin > 1
                % 指定版本
                version = varargin{1};
                key = sprintf('%s:%s', name, version);

                if ~AlgorithmRegistry.registry.isKey(key)
                    error('AlgorithmRegistry:NotFound', ...
                        'Algorithm %s version %s not found in registry', ...
                        name, version);
                end

                algorithmClass = AlgorithmRegistry.registry(key);
            else
                % 查找最新版本
                keys = AlgorithmRegistry.registry.keys;
                matchingKeys = {};

                for i = 1:length(keys)
                    if startsWith(keys{i}, [name ':'])
                        matchingKeys{end+1} = keys{i}; %#ok<AGROW>
                    end
                end

                if isempty(matchingKeys)
                    error('AlgorithmRegistry:NotFound', ...
                        'Algorithm %s not found in registry', name);
                end

                % 选择最后一个版本（假设按时间排序）
                key = matchingKeys{end};
                algorithmClass = AlgorithmRegistry.registry(key);
            end
        end

        function algorithms = listAlgorithms()
            % listAlgorithms 列出所有已注册算法
            %
            % 输出参数:
            %   algorithms - 结构体数组，包含 name 和 version 字段
            %
            % 示例:
            %   algs = AlgorithmRegistry.listAlgorithms();
            %   disp(algs);

            keys = AlgorithmRegistry.registry.keys;
            nAlgorithms = length(keys);
            algorithms = struct('name', cell(1, nAlgorithms), ...
                               'version', cell(1, nAlgorithms));

            for i = 1:nAlgorithms
                parts = strsplit(keys{i}, ':');
                algorithms(i).name = parts{1};
                algorithms(i).version = parts{2};
            end
        end

        function tf = isRegistered(name, varargin)
            % isRegistered 检查算法是否已注册
            %
            % 输入参数:
            %   name - 算法名称
            %   version - (可选) 版本号
            %
            % 输出参数:
            %   tf - true 表示已注册，false 表示未注册
            %
            % 示例:
            %   if AlgorithmRegistry.isRegistered('GWO')
            %       disp('GWO is available');
            %   end

            try
                if nargin > 1
                    version = varargin{1};
                    key = sprintf('%s:%s', name, version);
                    tf = AlgorithmRegistry.registry.isKey(key);
                else
                    keys = AlgorithmRegistry.registry.keys;
                    tf = false;
                    for i = 1:length(keys)
                        if startsWith(keys{i}, [name ':'])
                            tf = true;
                            break;
                        end
                    end
                end
            catch
                tf = false;
            end
        end

        function unregister(name, version)
            % unregister 注销算法
            %
            % 输入参数:
            %   name - 算法名称
            %   version - 版本号
            %
            % 注意: 此方法主要用于测试，生产环境慎用
            %
            % 示例:
            %   AlgorithmRegistry.unregister('test_algorithm', '0.1.0');

            key = sprintf('%s:%s', name, version);

            if AlgorithmRegistry.registry.isKey(key)
                AlgorithmRegistry.registry.remove(key);
            else
                warning('AlgorithmRegistry:NotFound', ...
                    'Algorithm %s version %s not found', name, version);
            end
        end

        function clear()
            % clear 清空注册表
            %
            % 注意: 此方法主要用于测试，生产环境慎用

            keys = AlgorithmRegistry.registry.keys;
            for i = 1:length(keys)
                AlgorithmRegistry.registry.remove(keys{i});
            end
        end

        function info = getAlgorithmInfo(name, version)
            % getAlgorithmInfo 获取算法详细信息
            %
            % 输入参数:
            %   name - 算法名称
            %   version - 版本号
            %
            % 输出参数:
            %   info - 包含算法元数据的结构体
            %
            % 示例:
            %   info = AlgorithmRegistry.getAlgorithmInfo('GWO', '1.0.0');
            %   disp(info);

            algorithmClass = AlgorithmRegistry.getAlgorithm(name, version);

            % 创建临时实例以获取参数模式
            try
                tempInstance = algorithmClass(struct());
                if isprop(tempInstance, 'PARAM_SCHEMA')
                    schema = tempInstance.PARAM_SCHEMA;
                else
                    schema = struct();
                end

                info = struct(...
                    'name', name, ...
                    'version', version, ...
                    'class', algorithmClass, ...
                    'paramSchema', schema ...
                );
            catch ME
                warning(ME.identifier, '%s', ME.message);
                info = struct(...
                    'name', name, ...
                    'version', version, ...
                    'class', algorithmClass, ...
                    'paramSchema', struct() ...
                );
            end
        end
    end
end
