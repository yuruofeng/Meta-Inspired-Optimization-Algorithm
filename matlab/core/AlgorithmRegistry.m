classdef AlgorithmRegistry < handle
    % AlgorithmRegistry 统一算法注册表
    %
    % 兼容历史注册形式:
    %   AlgorithmRegistry.register('GWO', '2.0.0', @GWO)
    %   AlgorithmRegistry.register('PSO', @PSO)
    %   AlgorithmRegistry.register('AO', '1.0.0', 'AO')
    %
    % 内部统一保存 name、version、constructor 和 metadata，供 MATLAB API、
    % Python 后端和前端目录数据共同使用。

    methods (Static)
        function register(name, varargin)
            % register 注册算法类并生成统一元数据

            [version, algorithmClass, metadata] = AlgorithmRegistry.parseRegisterArgs(varargin{:});
            constructor = AlgorithmRegistry.normalizeConstructor(algorithmClass);
            key = sprintf('%s:%s', char(name), char(version));

            registry = AlgorithmRegistry.registryStore();
            registry(key) = struct( ...
                'name', char(name), ...
                'version', char(version), ...
                'constructor', constructor, ...
                'metadata', AlgorithmRegistry.buildMetadata(char(name), char(version), constructor, metadata) ...
            );
        end

        function algorithmClass = getAlgorithm(name, varargin)
            % getAlgorithm 获取算法构造函数句柄

            entry = AlgorithmRegistry.getEntry(name, varargin{:});
            algorithmClass = entry.constructor;
        end

        function algorithms = listAlgorithms()
            % listAlgorithms 列出所有已注册算法

            entries = AlgorithmRegistry.listEntries();
            nAlgorithms = numel(entries);
            algorithms = struct('name', cell(1, nAlgorithms), 'version', cell(1, nAlgorithms));

            for i = 1:nAlgorithms
                algorithms(i).name = entries{i}.name;
                algorithms(i).version = entries{i}.version;
            end
        end

        function metadata = listMetadata()
            % listMetadata 返回所有已注册算法的 API 元数据

            entries = AlgorithmRegistry.listEntries();
            if isempty(entries)
                metadata = struct([]);
                return;
            end

            metadata = repmat(entries{1}.metadata, 1, numel(entries));
            for i = 1:numel(entries)
                metadata(i) = entries{i}.metadata;
            end
        end

        function tf = isRegistered(name, varargin)
            % isRegistered 检查算法是否已注册

            try
                AlgorithmRegistry.getEntry(name, varargin{:});
                tf = true;
            catch
                tf = false;
            end
        end

        function unregister(name, version)
            % unregister 注销指定算法版本

            key = sprintf('%s:%s', char(name), char(version));
            registry = AlgorithmRegistry.registryStore();
            if registry.isKey(key)
                remove(registry, key);
            else
                warning('AlgorithmRegistry:NotFound', ...
                    'Algorithm %s version %s not found', char(name), char(version));
            end
        end

        function clear()
            % clear 清空注册表，主要用于测试

            registry = AlgorithmRegistry.registryStore();
            keys = registry.keys;
            for i = 1:numel(keys)
                remove(registry, keys{i});
            end
        end

        function info = getAlgorithmInfo(name, varargin)
            % getAlgorithmInfo 获取算法详细信息

            entry = AlgorithmRegistry.getEntry(name, varargin{:});
            info = entry.metadata;
            info.class = entry.constructor;
        end
    end

    methods (Static, Access = private)
        function registry = registryStore()
            persistent registryMap
            if isempty(registryMap)
                registryMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            end
            registry = registryMap;
        end

        function [version, algorithmClass, metadata] = parseRegisterArgs(varargin)
            metadata = struct();

            if nargin == 1
                version = '1.0.0';
                algorithmClass = varargin{1};
            elseif nargin == 2
                version = varargin{1};
                algorithmClass = varargin{2};
            elseif nargin >= 3
                version = varargin{1};
                algorithmClass = varargin{2};
                metadata = varargin{3};
            else
                error('AlgorithmRegistry:InvalidArguments', ...
                    'register requires algorithm class information');
            end
        end

        function constructor = normalizeConstructor(algorithmClass)
            if isa(algorithmClass, 'function_handle')
                constructor = algorithmClass;
            elseif ischar(algorithmClass) || isstring(algorithmClass)
                constructor = str2func(char(algorithmClass));
            else
                error('AlgorithmRegistry:InvalidClass', ...
                    'algorithmClass must be a function handle, string, or char');
            end
        end

        function entry = getEntry(name, varargin)
            registry = AlgorithmRegistry.registryStore();

            if nargin > 1
                key = sprintf('%s:%s', char(name), char(varargin{1}));
                if ~registry.isKey(key)
                    error('AlgorithmRegistry:NotFound', ...
                        'Algorithm %s version %s not found in registry', char(name), char(varargin{1}));
                end
                entry = registry(key);
                return;
            end

            keys = registry.keys;
            matchingKeys = {};
            for i = 1:numel(keys)
                if startsWith(keys{i}, [char(name) ':'])
                    matchingKeys{end + 1} = keys{i}; %#ok<AGROW>
                end
            end

            if isempty(matchingKeys)
                error('AlgorithmRegistry:NotFound', ...
                    'Algorithm %s not found in registry', char(name));
            end

            entry = registry(matchingKeys{end});
        end

        function entries = listEntries()
            registry = AlgorithmRegistry.registryStore();
            keys = registry.keys;
            entries = cell(1, numel(keys));

            for i = 1:numel(keys)
                entries{i} = registry(keys{i});
            end
        end

        function metadata = buildMetadata(name, version, constructor, metadata)
            if nargin < 4 || isempty(fieldnames(metadata))
                metadata = struct();
            end

            metadata = AlgorithmRegistry.ensureField(metadata, 'id', name);
            metadata = AlgorithmRegistry.ensureField(metadata, 'name', name);
            metadata = AlgorithmRegistry.ensureField(metadata, 'fullName', name);
            metadata = AlgorithmRegistry.ensureField(metadata, 'version', version);
            metadata = AlgorithmRegistry.ensureField(metadata, 'description', sprintf('%s optimization algorithm', name));
            metadata = AlgorithmRegistry.ensureField(metadata, 'category', AlgorithmRegistry.inferCategory(name));
            metadata = AlgorithmRegistry.ensureField(metadata, 'reference', struct());
            metadata = AlgorithmRegistry.ensureField(metadata, 'paramSchema', AlgorithmRegistry.readParamSchema(constructor));
            metadata.paramSchema = AlgorithmRegistry.normalizeParamSchema(metadata.paramSchema);
        end

        function data = ensureField(data, fieldName, defaultValue)
            if ~isfield(data, fieldName) || isempty(data.(fieldName))
                data.(fieldName) = defaultValue;
            end
        end

        function schema = readParamSchema(constructor)
            schema = struct();
            className = func2str(constructor);
            try
                schema = eval([className '.PARAM_SCHEMA']);
            catch
                try
                    instance = constructor(struct());
                    if isprop(instance, 'PARAM_SCHEMA')
                        schema = instance.PARAM_SCHEMA;
                    end
                catch
                    schema = struct();
                end
            end
        end

        function schema = normalizeParamSchema(schema)
            if isempty(schema) || isempty(fieldnames(schema))
                return;
            end

            names = fieldnames(schema);
            for i = 1:numel(names)
                item = schema.(names{i});
                if isfield(item, 'type') && strcmp(item.type, 'double')
                    item.type = 'float';
                end
                if ~isfield(item, 'description')
                    item.description = names{i};
                end
                schema.(names{i}) = item;
            end
        end

        function category = inferCategory(name)
            evolutionary = {'GA', 'DE', 'TLBO'};
            physics = {'SA', 'ASO'};
            hybrid = {'IGWO', 'EWOA', 'WOASA', 'PSOGSA', 'HLBDA', 'VPSO', 'VPPSO', 'NRBO'};

            if startsWith(name, 'MO') || any(strcmp(name, {'MSSA', 'NSGAIII'}))
                category = 'hybrid';
            elseif any(strcmp(name, evolutionary))
                category = 'evolutionary';
            elseif any(strcmp(name, physics))
                category = 'physics';
            elseif any(strcmp(name, hybrid))
                category = 'hybrid';
            else
                category = 'swarm';
            end
        end
    end
end
