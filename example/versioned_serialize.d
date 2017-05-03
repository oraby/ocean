module versioned_serialize;

struct SSS (ubyte V)
{
    enum StructVersion = V; // Serializer looks for this
    static if (V == 1) {
        int id_as_int;
    }

    static if (V == 2){
        char[] id_as_string;
        alias StructPrevious = SSS!(1); // Serializer looks for this
        static void convert_id_as_string (ref SSS!1 src, ref SSS!2 dst) {
           import std.conv : to;
           dst.id_as_string = src.id_as_int.to!(char[]);
        }
    }
}

void test3 ()
{
    SSS!1 s1 = {id_as_int: 42};
    // Serialize
    import ocean.util.serialize.contiguous.MultiVersionDecorator;
    auto version_decorator = new VersionDecorator();
    void[] data;
    version_decorator.store(s1, data);

    // Load as s1 as S2
    import ocean.util.serialize.contiguous.Contiguous;
    Contiguous!(SSS!2) s2_buf;
    auto s2 = *version_decorator.loadCopy(data, s2_buf).ptr;
    import std.stdio;
    writeln("S2.id_as_str is: ", s2.id_as_string);
}

struct SS (ubyte V)
{
    static if (V == 1) alias int ID;
    static if (V == 2) alias char[] ID;
    static if (V == 3) alias hash_t ID;

    static if (V > 1) alias StructPrevious = SS!(V-1);
    enum StructVersion = V;
    static if (V < 3) alias StructNext = SS!(V+1);

    ID user_id;

    static if (V > 1)
    static void convert_user_id (ref StructPrevious src, ref SS!(V) dst)
    {
        import std.conv : to;
        dst.user_id = src.user_id.to!ID;
    }


    static if (V < 3)
    static void convert_user_id (ref StructNext src, ref SS!(V) dst)
    {
        import std.conv : to;
        dst.user_id = src.user_id.to!ID;
    }
}

void test2 ()
{
    SS!1 s1 = {user_id: 42};
    // Serialize
    import ocean.util.serialize.contiguous.MultiVersionDecorator;
    auto version_decorator = new VersionDecorator();
    void[] data;
    version_decorator.store(s1, data);

    // Load as s1 as S2
    import ocean.util.serialize.contiguous.Contiguous;
    Contiguous!(SS!2) s2_buf;
    auto s2 = *version_decorator.loadCopy(data, s2_buf).ptr;
    import std.stdio;
    writeln("S2 is: ", s2);

    Contiguous!(SS!3) s3_buf;
    auto s3 = *version_decorator.loadCopy(data, s3_buf).ptr;
    writeln("S3 is: ", s3);
}

struct S (ubyte V)
{
    static if (V > 1) alias StructPrevious = S!(V-1);
    enum StructVersion = V;
    static if (V < 3) alias StructNext = S!(V+1);

    static if (V == 1)
    {
         int id_as_int;

         static void convert_id_as_int (ref S!2 src, ref S!1 dst)
         {
             import std.conv : to;
             dst.id_as_int = src.id_as_string.to!int;
         }
    }

    static if (V == 2)
    {
         char[] id_as_string;

         static void convert_id_as_string (ref S!1 src, ref S!2 dst)
         {
             import std.conv : to;
             dst.id_as_string = src.id_as_int.to!(char[]);
         }

         static void convert_id_as_string (ref S!3 src, ref S!2 dst)
         {
             import std.conv : to;
             dst.id_as_string = src.id_as_hash.to!(char[]);
         }
    }

    static if (V == 3)
    {
         hash_t id_as_hash;

         static convert_id_as_hash (ref S!2 src, ref S!3 dst)
         {
             import std.conv : to;
             dst.id_as_hash = src.id_as_string.to!hash_t * 100;
         }
    }
}


void test ()
{
    S!1 s1 = {id_as_int: 42};
    // Serialize
    import ocean.util.serialize.contiguous.MultiVersionDecorator;
    auto version_decorator = new VersionDecorator();
    void[] data;
    version_decorator.store(s1, data);

    // Load as s1 as S2
    import ocean.util.serialize.contiguous.Contiguous;
    Contiguous!(S!2) s2_buf;
    auto s2 = *version_decorator.loadCopy(data, s2_buf).ptr;
    import std.stdio;
    writeln("S2 is: ", s2);

    Contiguous!(S!3) s3_buf;
    auto s3 = *version_decorator.loadCopy(data, s3_buf).ptr;
    writeln("S3 is: ", s3);
}

void main ()
{
    import std.stdio;
    import ocean.transition : getMsg;
    import ocean.util.serialize.model.VersionDecoratorMixins : VersionHandlingException;
    try
    {
        test();
        test2();
        test3();
    }
    catch (VersionHandlingException e) writeln("E.msg: ", getMsg(e));
}
