function msg = repException(e)
   FTSASSERT(isa(e, 'MException'));
   msg = '';
   for i = length(e.stack):-1:2
       msg = [msg e.stack(i).name '(' num2str(e.stack(i).line) ')->']; %#ok<AGROW>
   end
   msg = [msg e.stack(1).name '(' num2str(e.stack(1).line) ')' 10 e.message]; 
end

