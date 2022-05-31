local algorithm={}
require 'functions'


--组合
function combination(arr,nCount,total,resultArr,head)
    head = head or 1
    resultArr = resultArr or {}
    if (#resultArr == nCount )  then
        --组合选的结果出来
        -- print(nCount,table.concat(resultArr,","))
        -- table.insert(total,resultArr)
        local a = clone(resultArr)
        table.insert(total,a)
    else
        for  i = head,#arr do
            if(#resultArr < nCount  ) then    
                table.insert(resultArr,arr[i])
                combination(arr,nCount,total,resultArr,i + 1)
                --回溯还原
                table.remove(resultArr)
            end
        end
    end
end



function algorithm.combination(arr,n)
    local tmp={}
    combination(arr,n,tmp)
    return tmp
end

-- --注意排列中的数字不能重复
-- --测试代码,在luaEditor中测试通过
-- local Data = {1,2,3,4,}
-- --fullPermutation(Data)
-- -- allPermutation(Data)

-- local s=os.time()

-- table.dump(tmp,"asdf")
-- local e = os.time()
-- -- print(e-s)
-- --combination(Data,2)

local TEST = false
if TEST then
    local a = algorithm.combination({1,2,3},2)
    table.dump(a,'test')
end


 
return algorithm
