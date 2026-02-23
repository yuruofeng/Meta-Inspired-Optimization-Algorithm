%% GWO算法演示脚本（简化版）
% 演示如何使用DemoTemplate快速创建演示脚本
%
% 作者：RUOFENG YU
% 版本: 3.0.0
% 日期: 2026

clear;

%% 配置算法参数
config = struct(...
    'populationSize', 30, ...
    'maxIterations', 500, ...
    'verbose', true ...
);

%% 使用DemoTemplate运行演示
demo = shared.templates.DemoTemplate('GWO', config, 'F1');
result = demo.run();
