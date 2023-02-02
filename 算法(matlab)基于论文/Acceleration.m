%%%满足加速定义的高于基线FHRBaseline振幅bpm幅度的阈值定义为acc_threshold，持续时间长度阈值为acc_keeptime
%%% 若孕妇满32孕周，acc_threshold = 15，acc_keeptime = 18
%%% 若孕妇未满32孕周，acc_threshold = 10，acc_keeptime = 12
%%% 识别小加速时，acc_threshold = 10，acc_keeptime = 10
for i = 1 : length(FHR_cut)
    if FHR_cut(i) > FHRTemp(i) + acc_threshold
        o = 1
        for i = 1 : 60
            if FHR_cut(o) < FHR_cut(i+1)
                o = i+1
                FHRPeak = FHR_cut(o) %FHRPeak为最大值数值，o为位置FHRPeakTime
            end
        end
    end
end  %Stage 1
for j = o : -1 : o-55 %从FHRPeakTime位置向前搜索55个胎心率点
    if FHR_cut(j) < FHRBaseline(j)+2 && FHR_cut(j) <= FHRPeak
        acc_start = j %找到acc_start
        break
    end
end
for k = o : o+55 %从FHRPeakTime位置向后搜索55个胎心率点
    if FHR_cut(k) < FHRBaseline(k)+2 && FHR_cut(k) <= FHRPeak
        acc_end = k %找到acc_end
        break
    end
end
%若k-j > acc_keeptime 将acc_start与acc_end之间的时间判断为一次胎心率加速
%接着从加速位置FHRPeakTime的一分钟后重新执行此步骤