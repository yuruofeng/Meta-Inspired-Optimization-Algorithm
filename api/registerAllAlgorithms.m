function registerAllAlgorithms()
% REGISTERALLALGORITHMS 注册所有算法到AlgorithmRegistry
%
% 此函数在MATLAB引擎启动时由Python API服务器调用，
% 将所有可用的元启发式算法注册到AlgorithmRegistry中。
%
% 用法:
%   registerAllAlgorithms()
%
% 作者: 元启发式算法工程规范委员会
% 版本: 1.0.0
% 日期: 2025

    % 群智能算法
    GWO.register();    % 灰狼优化器
    ALO.register();    % 蚁狮优化器
    WOA.register();    % 鲸鱼优化算法
    DA.register();     % 蜻蜓算法

    % 改进算法
    IGWO.register();   % 改进灰狼优化器
    EWOA.register();   % 增强鲸鱼优化算法

    % 二进制算法
    BDA.register();    % 二进制蜻蜓算法
    BBA.register();    % 二进制蝙蝠算法

    % 经典算法
    GA.register();     % 遗传算法
    SA.register();     % 模拟退火

    % 变体算法
    VPSO.register();   % 变速度粒子群优化
    VPPSO.register();  % 变参数粒子群优化

    % 混合算法
    WOASA.register();  % WOA-SA混合算法

    % 输出注册信息
    algorithms = AlgorithmRegistry.listAlgorithms();
    fprintf('已注册 %d 个算法到AlgorithmRegistry\n', length(algorithms));
    for i = 1:length(algorithms)
        fprintf('  - %s (v%s)\n', algorithms(i).name, algorithms(i).version);
    end
end
