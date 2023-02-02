clear all
load('D:/DataMatrix_3Var.mat')
Newdt = resample(DataMatrix,20,2000)
save('D:/Newdt.mat','Newdt')
subplot(311) 
plot(Newdt(:,1))%胎音
subplot(312) 
plot(Newdt(:,2))%宫缩
subplot(313) 
plot(Newdt(:,3))%打标

% datadpl = zeros(1, length(Newdt))      %胎音
% datatoco = zeros(1,length(Newdt))     %宫缩
% datamove = zeros(1,length(Newdt))     %打标

%Andersson
[NameFileEcg, PathFileEcg] =uigetfile('*.fhr','file ECG');%文件导入
fid = fopen([PathFileEcg NameFileEcg],'r');
[hr,len] = fread(fid,'int16');
fclose(fid);

A=importdata('fhr(1).txt')%txt导入
a = A'

FHR = A
FHR(FHR == 0) = [ ] %零值部分去除
len = length(FHR)
FHR_mean = mean(FHR(:)) %求均值
for i = 1:length(FHR) %去除首部无效胎心值
    if FHR(i) < FHR_mean - 60
    else
        FHR(1:i-1) = [ ]
        cut_start = i %步骤6中用到
        break
    end
end
for i = length(FHR):-1:1 %去除尾部无效胎心值
    if FHR(i) < FHR_mean - 60
    else
        FHR(i+1:length(FHR)) = [ ]
        cut_end = i %步骤6中用到
        break
    end
end
FHR_cut = FHR %新的胎心率曲线

%%%%%第一轮线性插值更换
for i = 1:length(FHR_cut) %寻找i_start
    if abs(FHR_cut(i+1)- FHR_cut(i))  < 30
    else
        j = i % j = i_start
        break
    end
end
for i = j : j+400   %寻找i_end
    if abs(FHR_cut(i+1) - FHR_cut(i))  < 10 && abs(FHR_cut(i+1) - FHR_mean) < 30
        k = i % k = i_end
        break
    end
end

len = k-j+1
subs=interp1(len , FHR_cut(j:k) , 'nearest')  %求最近邻点插值
for  i = 1:length(subs) % 用插值替换从i_start至i_end的值
    FHR_cut(j)  = subs(i)
    j =  j+1
end

%%%%%第二轮线性插值更换（可重复执行该段代码）
for i = k+1:length(FHR_cut) %寻找i_start
    if abs(FHR_cut(i+1)- FHR_cut(i))  < 30
    else
        j = i % j = i_start
        break
    end
end
for i = j : j+400   %寻找i_end
    if abs(FHR_cut(i+1) - FHR_cut(i))  < 10 && abs(FHR_cut(i+1) - FHR_mean) < 50
        k = i % k = i_end
        break
    end
end

%新的i_start和i_end 做线性插值更换
len = k-j+1
subs=interp1(len , FHR_cut(j:k) , 'nearest')  %求最近邻点插值
for  i = 1:length(subs) % 用插值替换从i_start至i_end的值
    FHR_cut(j)  = subs(i)
    j =  j+1
end

FHR_ps = 60000./FHR_cut %以bmp为单位转换为以ms为单位的FHR_ps
FHR_ps(FHR_ps >300 & FHR_ps < 600) = [ ] %去除在300ms - 600ms以外的元素
PS_max = mode(FHR_ps) %取IBI值中频数最高
PSSum = length(FHR_ps) %各IBI值频数和
Ascend_ps = sort(FHR_ps,'ascend') %升序排序
sum = 0
for i = 1:PSSum
    if sum <= 0.875 * PSSum
        sum = sum +Ascend_ps(i)
        i = i+1
    else
        PST_start = Ascend_ps(i)
        break
    end
end %求PST_start

Decend_ps = sort(FHR_ps,'descend')
for i = 1:length(Decend_ps)%寻找降序排列中PST_start的位置记为p
    if Decend_ps(i) == PST_start
        p = i
        break
    end
end

while (true)
    FHRPS_j = Decend_ps(i)
        for i = i : i + ceil(length(Decend_ps) * 0.125)
            Decend_ps(i) > PS_max
            for o = i+1 : i+4
                if sum(Decend_ps == Decend_ps(i)) > sum(Decend_ps == Decend_ps(o))
                    break
                end
                for i = p : length(Decend_ps)
                    if sum(Decend_ps == Decend_ps(i)) >0.005 * PSSum || abs(PS_max - PST_start) < 30
                        break
                    end
                end
            end
        end
        break
end %寻找满足条件的FHRPS_j
PS_max = FHRPS_j %更新PS_max的值

%%%%%对FHRBase进行更新,并进行滤波(滤波5次,和4次修剪交替进行)
FHRTemp = FHR_cut
FHRBase = PS_max
for i = length(FHRTemp):-1:1 
    if abs(FHRTemp(i) - FHRBase) < 50
        FHRBase = 0.975 * FHRBase + 0.025 * FHRTemp(i)
        break
    end
end
%前向滤波操作
for m = 1:length(FHRTemp)
    if abs(FHRTemp(m) -FHRBase) < 50
        if m = 0
            FHRTemp(m) = 0.975 * FHRBase + 0.025 * FHRTemp(m)
        elseif m > 0
            FHRTemp(m) = 0.975 * FHRTemp(m-1) +0.025 * FHRTemp(m)
        end
    else
        if m = 0
            FHRTemp(m) = FHRBase
        elseif m > 0
            FHRTemp(m) = FHRTemp(m-1)
        end
    end
end
%后向滤波操作
for n = 1:length(FHRTemp)
    FHRTemp(n) = 0.975 * FHRTemp(n+1) + 0.025 * FHRBase
end

%%%%%修剪操作(4次) 其中V_k的值分别为20,15,10和5.  V_l的值分别为20,15,10和10.
for i = 1:length(FHR_cut)
    if FHR_cut(i) > FHR_Temp(i) +V_k && FHR_cut(i+1) < FHRTemp(i+1)
        p_end = i
        break
    end
end
for k = p_end:-1:1
    if FHR_cut(k) < FHRTemp(k)
        p_start = k
        break
    end
end

NewFHRTemp = zeros(1,length(FHR_cut))%定义新的序列NewFHRTemp
for i = 1:length(FHR_cut)
    if i>p_start && i<p_end
        NewFHRTemp(i) = FHRTemp(i)
    else
        NewFHRTemp(i) = FHR_cut(i)
    end
end%按照定义赋值

%%%%%若上述操作无法实行 按照下面操作赋值新序列NewFHRTemp
for i = 1:length(FHR_cut)
    if FHR_cut(i) < FHR_Temp(i) -V_l && FHR_cut(i+1) > FHRTemp(i+1)
        p_end = i
        break
    end
end
for k = p_end:-1:1
    if FHR_cut(k) > FHRTemp(k)
        p_start = k
        break
    end
end

NewFHRTemp = zeros(1,length(FHR_cut))
for i = 1:length(FHR_cut)
    if i>p_start && i<p_end
        NewFHRTemp(i) = FHRTemp(i)
    else
        NewFHRTemp(i) = FHR_cut(i)
    end
end%按照定义赋值
%上述修剪操作需分别手动修改v_k与v_l的值4次
FHRTemp = NewFHRTemp %进行5次滤波和4次修剪后做替换

%%%%%将新的胎心率曲线与原胎心率曲线对齐
FHR_cutcopy = FHR_cut
FHRTempcopy = FHRTemp
for i = 1:len
    if cut_start < i && cut_end > i 
        FHR_cut(i) = FHR_cutcopy(i - cut_start)
    else
        FHR_cut(i) = 0
    end
end
for i = 1:len
    if i < cut_start
        FHRTemp(i) = FHRTempcopy(cut_start)
    elseif i >= cut_start && i <= cut_end
         FHRTemp(i) = FHRTemp(i)
    elseif i > cut_end
         FHRTemp(i) = FHRTempcopy(cut_end)
    end
end
FHRBaseline = FHRTemp %将FHRTemp视为胎心率基线，并定义为FHRBaseline