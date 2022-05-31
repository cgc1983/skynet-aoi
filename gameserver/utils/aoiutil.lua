--AOI 辅助计算函数

local _M = {}

-- 计算两个点之间的距离
function _M.DIST2(p1,p2)
	return ((p1.x - p2.x) * (p1.x  - p2.x) + (p1.y  - p2.y) * (p1.y  - p2.y) + (p1.z  - p2.z) * (p1.z  - p2.z))
end


return _M