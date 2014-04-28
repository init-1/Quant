function o = LoadRiskModel(o)
    o.riskmodel = RiskEMA(o.aggid, o.bmhd.dates, 0);
    fields = fieldnames(o.bmhd,1);
    o.riskmodel.exposure = padfield(o.riskmodel.exposure, fields, NaN, 1);
    o.riskmodel.specrisk = padfield(o.riskmodel.specrisk, fields, NaN, 1);
    o.riskmodel.beta = padfield(o.riskmodel.beta, fields, NaN, 1);
end