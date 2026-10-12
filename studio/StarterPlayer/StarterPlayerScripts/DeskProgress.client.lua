--!strict
-- Fills the progress bar over every client's head, on every firm, from the desk's CaseStart/CaseEnd.
-- (perf 2026-10-09: each desk's bar is found once and remembered - it used to search every client model on every
-- firm with a recursive FindFirstChild every frame - and only bars that are actually showing are updated.)

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

type Bar = { client: Instance, gui: BillboardGui?, fill: Frame? }
local bars: { [Instance]: Bar } = {}

local function barOf(desk: Instance): Bar?
	local client = desk:FindFirstChild("Client")
	if not client then
		bars[desk] = nil
		return nil
	end
	local bar = bars[desk]
	if not bar or bar.client ~= client or not (bar.fill and bar.fill.Parent) then
		local gui = client:FindFirstChild("Nameplate") :: BillboardGui?
		local fill = client:FindFirstChild("Fill", true) :: Frame?
		bar = { client = client, gui = gui, fill = fill }
		bars[desk] = bar
	end
	return bar
end

CollectionService:GetInstanceRemovedSignal("Desk"):Connect(function(desk)
	bars[desk] = nil
end)

RunService.RenderStepped:Connect(function()
	local t = workspace:GetServerTimeNow()
	for _, desk in CollectionService:GetTagged("Desk") do
		local bar = barOf(desk)
		local fill = bar and bar.fill
		if not fill or (bar.gui and not bar.gui.Enabled) then
			continue
		end
		local start = desk:GetAttribute("CaseStart") :: number?
		local finish = desk:GetAttribute("CaseEnd") :: number?
		if start and finish and finish > start then
			fill.Size = UDim2.fromScale(math.clamp((t - start) / (finish - start), 0, 1), 1)
		end
	end
end)
