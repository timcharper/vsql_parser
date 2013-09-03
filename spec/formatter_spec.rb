require 'spec_helper'

module VSql
  describe Formatter do
    include TestChamber

    it "capitalizes keywords, putting each statement on their own line" do
      q = pparse("select v1 as s, v2 from table left join a on b = c where (table.v2 = '1') order by v2 limit 5")
      Formatter.format(q).should == <<-EOF
SELECT
  v1 AS s,
  v2
FROM table
LEFT JOIN a ON b = c
WHERE (table.v2 = '1')
ORDER BY v2
LIMIT 5
EOF
    end
    
    it "indents subqueries" do
      q = parse("select v1 from (select v2, v3 from a) b")

      Formatter.format(q).should == <<-EOF
SELECT
  v1
FROM (
  SELECT
    v2,
    v3
  FROM a) b
EOF
    end
  end
end
