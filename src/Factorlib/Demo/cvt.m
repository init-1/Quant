function cvt(fname)
   load(fname);
   for i = 1:length(ofac)
       if isa(ofac{i}, 'myfints')
           ofac{i}.desc = class(ofac{i});
           ofac{i} = copy(myfints, ofac{i});
       end
   end
   save(fname, 'ofac');
end
