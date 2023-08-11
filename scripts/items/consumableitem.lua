ConsumableItem = CustomItem:extend()
ConsumableItem:set {
    FullIcon = ImageReference:FromPackRelativePath("images/0058.png"),
    EmptyIcon = ImageReference:FromPackRelativePath("images/0059.png"),
    MinCount = {
        value = 0,
        afterSet = function(self)
                self.AcquiredCount1 = self.AcquiredCount1
                self.ConsumedCount1 = self.ConsumedCount1
                self.AcquiredCount2 = self.AcquiredCount2
                self.ConsumedCount2 = self.ConsumedCount2
                self:UpdateBadgeAndIcon()
            end
    },
    MaxCount1 = {
        value = 0x7fffffff,
        afterSet = function(self)
                self.AcquiredCount1 = self.AcquiredCount1
                self.ConsumedCount1 = self.ConsumedCount1
                self:UpdateBadgeAndIcon()
            end
    },
    MaxCount2 = {
        value = 0x7fffffff,
        afterSet = function(self)
                self.AcquiredCount2 = self.AcquiredCount2
                self.ConsumedCount2 = self.ConsumedCount2
                self:UpdateBadgeAndIcon()
            end
    },
    AcquiredCount1 = {
        value = 0,
        set = function(self, value) return math.min(math.max(math.max(value, self.ConsumedCount1), self.MinCount), self.MaxCount1) end,
        afterSet = function(self)
                self:UpdateBadgeAndIcon()
                self:InvalidateAccessibility()
            end
    },
    AcquiredCount2 = {
        value = 0,
        set = function(self, value) return math.min(math.max(math.max(value, self.ConsumedCount2), self.MinCount), self.MaxCount2) end,
        afterSet = function(self)
                self:UpdateBadgeAndIcon()
                self:InvalidateAccessibility()
            end
    },
    ConsumedCount1 = {
        value = 0,
        set = function(self, value) return math.max(math.min(value, self.AvailableCount1), 0) end,
        afterSet = function(self)
                self:UpdateBadgeAndIcon()
                self:InvalidateAccessibility()
            end
    },
    ConsumedCount2 = {
        value = 0,
        set = function(self, value) return math.max(math.min(value, self.AvailableCount2), 0) end,
        afterSet = function(self)
                self:UpdateBadgeAndIcon()
                self:InvalidateAccessibility()
            end
    },
    AvailableCount1 = {
        get = function(self) return self.AcquiredCount1 - self.ConsumedCount1 end
    },
    AvailableCount2 = {
        get = function(self) return self.AcquiredCount2 - self.ConsumedCount2 end
    },
    DisplayFractionOfMax = {
        value = true,
        afterSet = function(self) self:UpdateBadgeAndIcon() end
    },
    CountIncrement1 = 1,
    CountIncrement2 = 1,
    SwapActions = true
}

function ConsumableItem:init(name, code, maxqty1, maxqty2, inc1, inc2, img, disabledImg)
    maxqty1 = maxqty1 or self.MaxCount1
    maxqty2 = maxqty2 or self.MaxCount2
    inc1 = inc1 or self.CountIncrement1
    inc2 = inc2 or self.CountIncrement2

    self:createItem(name)

    code = string.gsub(code, " ", "")
    self.codes = {}
    if string.find(code, ",") ~= nil then
        for str in string.gmatch(code, "([^,]+)") do
            table.insert(self.codes, str)
        end
    else table.insert(self.codes, code)
    end

    self.MaxCount1 = maxqty1
    self.MaxCount2 = maxqty2
    self.CountIncrement1 = inc1
    self.CountIncrement2 = inc2
    if img then
        self.FullIcon = ImageReference:FromPackRelativePath(img, "@enabled")
    end
    if disabledImg then
        self.EmptyIcon = ImageReference:FromPackRelativePath(disabledImg, "@disabled")
    elseif img then
        self.EmptyIcon = ImageReference:FromPackRelativePath(img, "@disabled")
    end

    self:UpdateBadgeAndIcon()
end

function ConsumableItem:UpdateBadgeAndIcon()
    if self.AvailableCount1 == 0 then
        self.ItemInstance.Icon = self.AcquiredCount1 > 0 and self.FullIcon or self.EmptyIcon
        self.ItemInstance.BadgeText = nil
    else
        self.ItemInstance.Icon = self.FullIcon
        if not self.DisplayAsFractionOfMax then
            self.ItemInstance.BadgeText = self:Difficulty() == 0 and tostring(math.floor(self.AvailableCount1)) or tostring(math.floor(self.AvailableCount2))
        else
            self.ItemInstance.BadgeText = self:Difficulty() == 0 and tostring(math.floor(self.AvailableCount1)) .. "/" .. tostring(math.floor(self.MaxCount1))
                or tostring(math.floor(self.AvailableCount2)) .. "/" .. tostring(math.floor(self.MaxCount2))
        end
    end
    if self.AcquiredCount1 >= self.MaxCount1 then
        self.ItemInstance.BadgeTextColor = "#00ff00"
    else
        self.ItemInstance.BadgeTextColor = "WhiteSmoke"
    end
end

function ConsumableItem:Difficulty()
    if Tracker:ProviderCountForCode("DifficultyNormal") > 0 then
        return 0
    end
    return 1
end

function ConsumableItem:InvalidateAccessibility()
    self.ItemInstance:InvalidateAccessibility()
end

function ConsumableItem:Increment(count)
    count = count or 1
    local num1 = math.min(self.MaxCount1, math.max(self.MinCount, self.AcquiredCount1 + (self.CountIncrement1 * count)))
    self.AcquiredCount1 = num1
    local num2 = math.min(self.MaxCount2, math.max(self.MinCount, self.AcquiredCount2 + (self.CountIncrement2 * count)))
    self.AcquiredCount2 = num2
    return self:Difficulty() == 0 and num1 or num2
end

function ConsumableItem:Decrement(count)
    count = count or 1
    local num1 = math.min(self.MaxCount1, math.max(self.MinCount, self.AcquiredCount1 - (self.CountIncrement1 * count)))
    self.AcquiredCount1 = num1
    local num2 = math.min(self.MaxCount2, math.max(self.MinCount, self.AcquiredCount2 - (self.CountIncrement2 * count)))
    self.AcquiredCount2 = num2
    return self:Difficulty() == 0 and num1 or num2
end

function ConsumableItem:onLeftClick()
    if self.SwapActions then
        self:Increment(1)
    else
        self:Decrement(1)
    end
end

function ConsumableItem:onRightClick()
    if self.SwapActions then
        self:Decrement(1)
    else
        self:Increment(1)
    end
end

function ConsumableItem:canProvideCode(code)
    for i,c in ipairs(self.codes) do
        if code == c then
            return true
        end
    end
    return false
end

function ConsumableItem:providesCode(code)
    for i,c in ipairs(self.codes) do
        if code == c then
            return self:Difficulty() == 0 and self.AcquiredCount1 or self.AcquiredCount2
        end
    end
    return 0
end

function ConsumableItem:advanceToCode(code)
    for i,c in ipairs(self.codes) do
        if code == nil or code == c then
            self:OnLeftClick()
        end
    end
end

function ConsumableItem:save()
    local data = {}
    data["min_count"] = self.MinCount
    data["max_count1"] = self.MaxCount1
    data["max_count2"] = self.MaxCount2
    data["consumed_count1"] = self.ConsumedCount1
    data["consumed_count2"] = self.ConsumedCount2
    data["acquired_count1"] = self.AcquiredCount1
    data["acquired_count2"] = self.AcquiredCount2
    return data
end

function ConsumableItem:load(data)
    local num1 = -1
    local num2 = -1
    local num3 = -1
    local num4 = -1
    if data["acquired_count1"] ~= nil then
        num1 = data["acquired_count1"]
    end
    if data["acquired_count2"] ~= nil then
        num2 = data["acquired_count2"]
    end
    if data["consumed_count1"] ~= nil then
        num3 = data["consumed_count1"]
    end
    if data["consumed_count2"] ~= nil then
        num4 = data["consumed_count2"]
    end
    if num1 < 0 or num2 < 0 or num3 < 0 or num4 < 0 then
        return false
    end
    if data["max_count1"] ~= nil then
        self.MaxCount1 = data["max_count1"]
    end
    if data["max_count2"] ~= nil then
        self.MaxCount2 = data["max_count2"]
    end
    if data["min_count"] ~= nil then
        self.MinCount = data["min_count"]
    end
    self.AcquiredCount1 = num1
    self.AcquiredCount2 = num2
    self.ConsumedCount1 = num3
    self.ConsumedCount2 = num4
    return true
end
