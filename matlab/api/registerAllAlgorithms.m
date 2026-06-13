function registerAllAlgorithms()
% REGISTERALLALGORITHMS 注册所有可加载算法到 AlgorithmRegistry
%
% 单个算法类加载失败时记录警告并继续注册其他算法，避免一个实验性算法
% 阻断后端启动和算法目录读取。

    registrations = {
        'GWO', @() GWO.register();
        'ALO', @() ALO.register();
        'WOA', @() WOA.register();
        'DA', @() DA.register();
        'MFO', @() MFO.register();
        'MVO', @() MVO.register();
        'SCA', @() SCA.register();
        'SSA', @() SSA.register();
        'IGWO', @() IGWO.register();
        'EWOA', @() EWOA.register();
        'BDA', @() BDA.register();
        'BBA', @() BBA.register();
        'GA', @() GA.register();
        'SA', @() SA.register();
        'VPSO', @() VPSO.register();
        'VPPSO', @() VPPSO.register();
        'WOASA', @() WOASA.register();
        'PSOGSA', @() PSOGSA.register();
        'GOA', @() GOA.register();
        'HLBDA', @() HLBDA.register();
        'HGS', @() HGS.register();
        'AO', @() AO.register();
        'MPA', @() MPA.register();
        'GTO', @() GTO.register();
        'MOEAD', @() MOEAD.register();
        'AVOA', @() AVOA.register();
        'KOA', @() KOA.register();
        'RIME', @() RIME.register();
        'MOALO', @() MOALO.register();
        'MODA', @() MODA.register();
        'MOGOA', @() MOGOA.register();
        'MOGWO', @() MOGWO.register();
        'MSSA', @() MSSA.register();
        'NSGAIII', @() NSGAIII.register();
    };

    for i = 1:size(registrations, 1)
        safeRegister(registrations{i, 1}, registrations{i, 2});
    end

    algorithms = AlgorithmRegistry.listAlgorithms();
    fprintf('已注册 %d 个算法到AlgorithmRegistry\n', length(algorithms));
    for i = 1:length(algorithms)
        fprintf('  - %s (v%s)\n', algorithms(i).name, algorithms(i).version);
    end
end

function safeRegister(name, registerFn)
% SAFEREGISTER 单个算法注册容错封装

    try
        registerFn();
    catch ME
        warning('AlgorithmRegistry:RegisterFailed', ...
            '跳过算法 %s: %s', name, ME.message);
    end
end
