using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Text;
using gov.va.medora.mdo;

namespace gov.va.medora.mdws.dto
{
    public class TaggedCytologyRptArrays : AbstractArrayTO
    {
        public TaggedCytologyRptArray[] arrays;

        public TaggedCytologyRptArrays() { }

        public TaggedCytologyRptArrays(IndexedHashtable t)
        {
            if (t.Count == 0)
            {
                return;
            }
            arrays = new TaggedCytologyRptArray[t.Count];
            for (int i = 0; i < t.Count; i++)
            {
                if (t.GetValue(i) == null)
                {
                    arrays[i] = new TaggedCytologyRptArray((string)t.GetKey(i));
                }
                else if (MdwsUtils.isException(t.GetValue(i)))
                {
                    arrays[i] = new TaggedCytologyRptArray((string)t.GetKey(i), (Exception)t.GetValue(i));
                }
                else if (t.GetValue(i).GetType().IsArray)
                {
                    arrays[i] = new TaggedCytologyRptArray((string)t.GetKey(i), (CytologyReport[])t.GetValue(i));
                }
                else
                {
                    arrays[i] = new TaggedCytologyRptArray((string)t.GetKey(i), (CytologyReport)t.GetValue(i));
                }
            }
            count = t.Count;
        }
    }
}
