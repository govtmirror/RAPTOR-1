using System;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.Text;
using gov.va.medora.mdo;

namespace gov.va.medora.mdws.dto
{
    public class TaggedRadiologyReportArrays : AbstractArrayTO
    {
        public TaggedRadiologyReportArray[] arrays;

        public TaggedRadiologyReportArrays() { }

        public TaggedRadiologyReportArrays(IndexedHashtable t)
        {
            if (t.Count == 0)
            {
                return;
            }
            arrays = new TaggedRadiologyReportArray[t.Count];
            for (int i = 0; i < t.Count; i++)
            {
                if (t.GetValue(i) == null)
                {
                    arrays[i] = new TaggedRadiologyReportArray((string)t.GetKey(i));
                }
                else if (MdwsUtils.isException(t.GetValue(i)))
                {
                    arrays[i] = new TaggedRadiologyReportArray((string)t.GetKey(i), (Exception)t.GetValue(i));
                }
                else if (t.GetValue(i).GetType().IsArray)
                {
                    arrays[i] = new TaggedRadiologyReportArray((string)t.GetKey(i), (RadiologyReport[])t.GetValue(i));
                }
                else
                {
                    arrays[i] = new TaggedRadiologyReportArray((string)t.GetKey(i), (RadiologyReport)t.GetValue(i));
                }
            }
            count = t.Count;
        }
    }
}
