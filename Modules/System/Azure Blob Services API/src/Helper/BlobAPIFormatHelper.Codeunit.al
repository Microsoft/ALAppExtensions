// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 9044 "Blob API Format Helper"
{
    Access = Internal;

    procedure AppendToUri(var Uri: Text; ParameterIdentifier: Text; ParameterValue: Text)
    var
        ConcatChar: Text;
        AppendType1Lbl: Label '%1%2=%3', Comment = '%1 = Concatenation character, %2 = Parameter Identifer, %3 = Parameter Value';
        AppendType2Lbl: Label '%1%2', Comment = '%1 = Concatenation character, %2 = Parameter Value';
    begin
        ConcatChar := '?';
        if Uri.Contains('?') then
            ConcatChar := '&';
        if ParameterIdentifier <> '' then
            Uri += StrSubstNo(AppendType1Lbl, ConcatChar, ParameterIdentifier, ParameterValue)
        else
            Uri += StrSubstNo(AppendType2Lbl, ConcatChar, ParameterValue)
    end;

    procedure RemoveCurlyBracketsFromString("Value": Text): Text
    begin
        exit(DelChr("Value", '=', '{}'));
    end;

    procedure GetBase64BlockId(): Text
    begin
        exit(GetBase64BlockId(RemoveCurlyBracketsFromString(Format(CreateGuid()))));
    end;

    procedure GetBase64BlockId(BlockId: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Uri: Codeunit Uri;
    begin
        exit(Uri.EscapeDataString(Base64Convert.ToBase64(BlockId)));
    end;

    procedure BlockDictionariesToBlockListDictionary(CommitedBlocks: Dictionary of [Text, Integer]; UncommitedBlocks: Dictionary of [Text, Integer]; var BlockList: Dictionary of [Text, Text]; OverwriteValueToLatest: Boolean)
    var
        Keys: List of [Text];
        "Key": Text;
        "Value": Text;
    begin
        "Value" := 'Committed';
        If OverwriteValueToLatest then
            "Value" := 'Latest';
        Keys := CommitedBlocks.Keys;
        foreach "Key" in Keys do
            BlockList.Add("Key", "Value");

        "Value" := 'Uncommitted';
        If OverwriteValueToLatest then
            "Value" := 'Latest';
        Keys := UncommitedBlocks.Keys;
        foreach "Key" in Keys do
            BlockList.Add("Key", "Value");
    end;

    procedure CreateUserDelegationKeyBody(StartDateTime: DateTime; ExpiryDateTime: DateTime): XmlDocument
    var
        Document: XmlDocument;
        KeyInfoNode: XmlNode;
        ValueNode: XmlNode;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><KeyInfo></KeyInfo>', Document);
        Document.SelectSingleNode('/KeyInfo', KeyInfoNode);
        if StartDateTime <> 0DT then begin
            ValueNode := XmlElement.Create('Start', '', GetIso8601DateTime(StartDateTime)).AsXmlNode();
            KeyInfoNode.AsXmlElement().Add(ValueNode);
        end;
        ValueNode := XmlElement.Create('Expiry', '', GetIso8601DateTime(ExpiryDateTime)).AsXmlNode();
        KeyInfoNode.AsXmlElement().Add(ValueNode);
        exit(Document);
    end;

    procedure BlockListDictionaryToXmlDocument(BlockList: Dictionary of [Text, Text]): XmlDocument
    var
        Document: XmlDocument;
        BlockListNode: XmlNode;
        BlockNode: XmlNode;
        Keys: List of [Text];
        "Key": Text;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><BlockList></BlockList>', Document);
        Document.SelectSingleNode('/BlockList', BlockListNode);
        Keys := BlockList.Keys;
        foreach "Key" in Keys do begin
            BlockNode := XmlElement.Create(BlockList.Get("Key"), '', "Key").AsXmlNode(); // Dictionary value contains "Latest", "Committed" or "Uncommitted"
            BlockListNode.AsXmlElement().Add(BlockNode);
        end;
        exit(Document);
    end;

    procedure TagsDictionaryToXmlDocument(Tags: Dictionary of [Text, Text]): XmlDocument
    var
        Document: XmlDocument;
        TagSetNode: XmlNode;
        TagNode: XmlNode;
        KeyNode: XmlNode;
        ValueNode: XmlNode;
        Keys: List of [Text];
        "Key": Text;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><Tags><TagSet></TagSet></Tags>', Document);
        Document.SelectSingleNode('/Tags/TagSet', TagSetNode);
        Keys := Tags.Keys;
        foreach "Key" in Keys do begin
            TagNode := XmlElement.Create('Tag').AsXmlNode();
            KeyNode := XmlElement.Create('Key', '', "Key").AsXmlNode();
            ValueNode := XmlElement.Create('Value', '', Tags.Get("Key")).AsXmlNode();
            TagSetNode.AsXmlElement().Add(TagNode);

            TagNode.AsXmlElement().Add(KeyNode);
            TagNode.AsXmlElement().Add(ValueNode);
        end;
        exit(Document);
    end;

    procedure TagsDictionaryToSearchExpression(Tags: Dictionary of [Text, Text]): Text
    var
        Helper: Codeunit "Uri";
        Keys: List of [Text];
        "Key": Text;
        SingleQuoteChar: Char;
        Expression: Text;
        ExpressionPartLbl: Label '"%1" %2 %3%4%5', Comment = '%1 = Tag, %2 = Operator, %3 = Single Quote, %4 = Value, %5 = Single Quote';
    begin
        SingleQuoteChar := 39;
        Keys := Tags.Keys;
        foreach "Key" in Keys do begin
            if Expression <> '' then
                Expression += ' AND ';
            Expression += StrSubstNo(ExpressionPartLbl, "Key".Trim(), GetOperatorFromValue(Tags.Get("Key")).Trim(), SingleQuoteChar, GetValueWithoutOperator(Tags.Get("Key")).Trim(), SingleQuoteChar);
        end;
        Expression := Helper.EscapeDataString(Expression);
        exit(Expression);
    end;

    procedure QueryExpressionToQueryBlobContent(QueryExpression: Text): XmlDocument
    var
        Document: XmlDocument;
        QueryRequestNode: XmlNode;
        QueryTypeNode: XmlNode;
        ExpressionNode: XmlNode;
    begin
        XmlDocument.ReadFrom('<?xml version="1.0" encoding="utf-8"?><QueryRequest></QueryRequest>', Document);
        Document.SelectSingleNode('/QueryRequest', QueryRequestNode);
        QueryTypeNode := XmlElement.Create('QueryType', '', 'SQL').AsXmlNode();
        QueryRequestNode.AsXmlElement().Add(QueryTypeNode);
        ExpressionNode := XmlElement.Create('Expression', '', QueryExpression).AsXmlNode();
        QueryRequestNode.AsXmlElement().Add(ExpressionNode);
        exit(Document);
    end;

    local procedure GetOperatorFromValue("Value": Text): Text
    var
        NewValue: Text;
    begin
        NewValue := "Value".Substring(1, "Value".IndexOf(' '));
        exit(NewValue.Trim());
    end;

    local procedure GetValueWithoutOperator("Value": Text): Text
    var
        NewValue: Text;
    begin
        NewValue := "Value".Substring("Value".IndexOf(' ') + 1);
        exit(NewValue.Trim());
    end;

    procedure TextToXmlDocument(SourceText: Text): XmlDocument
    var
        Document: XmlDocument;
    begin
        XmlDocument.ReadFrom(SourceText, Document);
        exit(Document);
    end;

    procedure ConvertToDateTime(PropertyValue: Text): DateTime
    var
        NewDateTime: DateTime;
    begin
        NewDateTime := 0DT;
        // PropertyValue is something like the following: 'Mon, 24 May 2021 12:25:27 GMT'
        // 'Evaluate' converts these correctly
        Evaluate(NewDateTime, PropertyValue);
        exit(NewDateTime);
    end;

    procedure ConvertToInteger(PropertyValue: Text): Integer
    var
        NewInteger: Integer;
    begin
        if Evaluate(NewInteger, PropertyValue) then
            exit(NewInteger);
    end;

    procedure ConvertToBoolean(PropertyValue: Text): Boolean
    var
        NewBoolean: Boolean;
    begin
        if Evaluate(NewBoolean, PropertyValue) then
            exit(NewBoolean);
    end;

    procedure GetNewLineCharacter(): Text
    var
        LF: Char;
    begin
        LF := 10;
        exit(Format(LF));
    end;

    procedure GetIso8601DateTime(MyDateTime: DateTime): Text
    var
        DateTimeAsXmlString: Text;
    begin
        MyDateTime := ConvertDateTimeToUtcDateTime(MyDateTime);
        DateTimeAsXmlString := Format(MyDateTime, 0, 9); // Format as XML, e.g.: 2020-11-11T08:50:07.553Z
        if DateTimeAsXmlString.Contains('.') then
            DateTimeAsXmlString := DateTimeAsXmlString.Substring(1, DateTimeAsXmlString.LastIndexOf('.'));
        exit(DateTimeAsXmlString);
    end;

    procedure GetRfc1123DateTime(): Text
    begin
        exit(GetRfc1123DateTime(CreateDateTime(Today(), Time())));
    end;

    procedure GetRfc1123DateTime(MyDateTime: DateTime): Text
    var
        Rfc1123FormatDateTime: Text;
        TargetDateTimeFormatLbl: Label '<Weekday Text,3>, <Day> <Month Text,3> <Year4> <Hours24,2>:<Minutes,2>:<Seconds,2>';
        Rfc1123FormatLbl: Label '%1 GMT', Comment = '%1 = Correctly formatted Timestamp';
    begin
        // Target format is like this: Wed, 11 Nov 2020 08:50:07 GMT
        // Definition: https://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html "14.18 Date"
        MyDateTime := ConvertDateTimeToUtcDateTime(MyDateTime);
        Rfc1123FormatDateTime := GetDateFormatInEnglish(MyDateTime, TargetDateTimeFormatLbl);
        // Adjust if current day-value is below 10 to add a leading "0"
        // API is expecting format to be like:
        //     Tue, 01 Dec 2020 17:05:07 GMT
        // Previous code would generate it like:
        //     Tue, 1 Dec 2020 17:05:07 GMT
        // Since the day is always a 3-letter string followed by a comma and a space we need to add a "0" (zero) on pos 6 in these cases
        if Date2DMY(DT2Date(MyDateTime), 1) < 10 then
            Rfc1123FormatDateTime := InsStr(Rfc1123FormatDateTime, '0', 6);
        Rfc1123FormatDateTime := StrSubstNo(Rfc1123FormatLbl, Rfc1123FormatDateTime);
        exit(Rfc1123FormatDateTime);
    end;

    local procedure ConvertDateTimeToUtcDateTime(MyDateTime: DateTime): DateTime
    var
        UtcDate: Date;
        UtcTime: Time;
        UtcDateTime: DateTime;
        DateTimeAsXmlString: Text;
        DatePartText: Text;
        TimePartText: Text;
    begin
        // AFAIK is formatting an AL DateTime as XML the only way to get the UTC-value, so this is used as a workaround                
        DateTimeAsXmlString := Format(MyDateTime, 0, 9); // Format as XML, e.g.: 2020-11-11T08:50:07.553Z
        DatePartText := CopyStr(DateTimeAsXmlString, 1, StrPos(DateTimeAsXmlString, 'T') - 1);
        TimePartText := CopyStr(DateTimeAsXmlString, StrPos(DateTimeAsXmlString, 'T') + 1);
        if (StrPos(TimePartText, '.') > 0) then
            TimePartText := CopyStr(TimePartText, 1, StrPos(TimePartText, '.') - 1);
        if (StrPos(TimePartText, 'Z') > 0) then
            TimePartText := CopyStr(TimePartText, 1, StrPos(TimePartText, 'Z') - 1);
        Evaluate(UtcDate, DatePartText);
        Evaluate(UtcTime, TimePartText);
        UtcDateTime := CreateDateTime(UtcDate, UtcTime);
        exit(UtcDateTime);
    end;

    local procedure GetDateFormatInEnglish(MyDateTime: DateTime; FormatString: Text): Text
    var
        Language: Codeunit Language;
        CurrLanguageId: Integer;
        FormattedText: Text;
    begin
        CurrLanguageId := GlobalLanguage();
        GlobalLanguage(Language.GetDefaultApplicationLanguageId()); // Language.GetDefaultApplicationLanguageId() returns 1033 (for "en-us")
        FormattedText := Format(MyDateTime, 0, FormatString);
        GlobalLanguage(CurrLanguageId);
        exit(FormattedText);
    end;

    procedure CreateRandomBlobname(MaxLength: Integer): Text
    var
        Blobname: Text;
        AsciiChar: Char;
        RandInt: Integer;
    begin
        if MaxLength = 0 then
            MaxLength := Random(30);
        Randomize();
        while StrLen(Blobname) <= MaxLength do begin
            RandInt := Random(122);
            AsciiChar := RandInt;
            if Format(AsciiChar) in ['A' .. 'Z', 'a' .. 'z', '0' .. '9'] then
                Blobname += Format(AsciiChar);
        end;
        exit(Blobname);
    end;
}