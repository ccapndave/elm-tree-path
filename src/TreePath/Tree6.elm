module TreePath.Tree6 exposing
    ( Tree, TreePath1, TreePath2, TreePath3, TreePath4, TreePath5, TreePath6
    , DecoderConfig, decoder, pathDecoder, pathEncode1, pathEncode2, pathEncode3, pathEncode4, pathEncode5, pathEncode6
    , toRootPath
    , data1, data2, data3, data4, data5, data6
    , top1, up1, offset1, down1, downs1, top2, up2, offset2, down2, downs2, top3, up3, offset3, down3, downs3, top4, up4, offset4, down4, downs4, top5, up5, offset5, down5, downs5, top6, up6, offset6, down6, downs6
    )

{-| This module provides types and functions for managing a strongly typed tree
of depth 6. Each level of the tree can have its own type, and each level can
contain Data either of that type, or the leaf type.


# Definition

@docs Tree, TreePath1, TreePath2, TreePath3, TreePath4, TreePath5, TreePath6


# Encoders and decoders

@docs DecoderConfig, decoder, pathDecoder, pathEncode1, pathEncode2, pathEncode3, pathEncode4, pathEncode5, pathEncode6


# Path constructor

@docs toRootPath


# Data

@docs data1, data2, data3, data4, data5, data6


# Navigation

@docs top1, up1, offset1, down1, downs1, top2, up2, offset2, down2, downs2, top3, up3, offset3, down3, downs3, top4, up4, offset4, down4, downs4, top5, up5, offset5, down5, downs5, top6, up6, offset6, down6, downs6

-}

import Array exposing (Array)
import Json.Decode as JD exposing (Decoder)
import Json.Encode as JE exposing (Value)
import TreePath.Data as Data exposing (Data)


{-| -}
type alias Tree a b c d e leaf =
    Tree6 a b c d e leaf


type Tree1 leaf
    = Tree1
        { data : leaf
        }


type Tree2 a leaf
    = Tree2
        { data : Data a leaf
        , children : Array (Tree1 leaf)
        }


type Tree3 a b leaf
    = Tree3
        { data : Data a leaf
        , children : Array (Tree2 b leaf)
        }


type Tree4 a b c leaf
    = Tree4
        { data : Data a leaf
        , children : Array (Tree3 b c leaf)
        }


type Tree5 a b c d leaf
    = Tree5
        { data : Data a leaf
        , children : Array (Tree4 b c d leaf)
        }


type Tree6 a b c d e leaf
    = Tree6
        { data : Data a leaf
        , children : Array (Tree5 b c d e leaf)
        }


{-| -}
type TreePath1 a b c d e leaf
    = TreePath1 (Tree1 leaf) Int (TreePath2 a b c d e leaf)


{-| -}
type TreePath2 a b c d e leaf
    = TreePath2 (Tree2 e leaf) Int (TreePath3 a b c d e leaf)


{-| -}
type TreePath3 a b c d e leaf
    = TreePath3 (Tree3 d e leaf) Int (TreePath4 a b c d e leaf)


{-| -}
type TreePath4 a b c d e leaf
    = TreePath4 (Tree4 c d e leaf) Int (TreePath5 a b c d e leaf)


{-| -}
type TreePath5 a b c d e leaf
    = TreePath5 (Tree5 b c d e leaf) Int (TreePath6 a b c d e leaf)


{-| -}
type TreePath6 a b c d e leaf
    = TreePath6 (Tree6 a b c d e leaf) () ()


{-| -}
type alias DecoderConfig a b c d e leaf path =
    { level6 :
        { decoder : Decoder a
        , encoders : a -> List ( String, Value )
        , pathType : TreePath6 a b c d e leaf -> path
        , childrenField : String
        }
    , level5 :
        { decoder : Decoder b
        , encoders : b -> List ( String, Value )
        , pathType : TreePath5 a b c d e leaf -> path
        , childrenField : String
        }
    , level4 :
        { decoder : Decoder c
        , encoders : c -> List ( String, Value )
        , pathType : TreePath4 a b c d e leaf -> path
        , childrenField : String
        }
    , level3 :
        { decoder : Decoder d
        , encoders : d -> List ( String, Value )
        , pathType : TreePath3 a b c d e leaf -> path
        , childrenField : String
        }
    , level2 :
        { decoder : Decoder e
        , encoders : e -> List ( String, Value )
        , pathType : TreePath2 a b c d e leaf -> path
        , childrenField : String
        }
    , leaf :
        { decoder : Decoder leaf
        , encode : leaf -> Value
        , pathType : TreePath1 a b c d e leaf -> path
        }
    }


{-| -}
decoder : DecoderConfig a b c d e leaf path -> Decoder (Tree6 a b c d e leaf)
decoder config =
    decoder6
        ( config.level6.decoder, config.level6.childrenField )
        ( config.level5.decoder, config.level5.childrenField )
        ( config.level4.decoder, config.level4.childrenField )
        ( config.level3.decoder, config.level3.childrenField )
        ( config.level2.decoder, config.level2.childrenField )
        config.leaf.decoder


encode : DecoderConfig a b c d e leaf path -> Tree6 a b c d e leaf -> Value
encode config tree =
    encode6
        ( config.level6.encoders, config.level6.childrenField )
        ( config.level5.encoders, config.level5.childrenField )
        ( config.level4.encoders, config.level4.childrenField )
        ( config.level3.encoders, config.level3.childrenField )
        ( config.level2.encoders, config.level2.childrenField )
        config.leaf.encode
        tree


{-| -}
pathDecoder : DecoderConfig a b c d e leaf path -> Decoder path
pathDecoder config =
    JD.field "tree" (decoder config)
        |> JD.andThen
            (\tree ->
                JD.field "path" (JD.list JD.int)
                    |> JD.andThen
                        (\path ->
                            case path of
                                [] ->
                                    Just (TreePath6 tree () ())
                                        |> Maybe.map config.level6.pathType
                                        |> Maybe.map JD.succeed
                                        |> Maybe.withDefault (JD.fail "Illegal path branch index")

                                [ b1 ] ->
                                    Just (TreePath6 tree () ())
                                        |> Maybe.andThen (down6 b1)
                                        |> Maybe.map config.level5.pathType
                                        |> Maybe.map JD.succeed
                                        |> Maybe.withDefault (JD.fail "Illegal path branch index")

                                [ b1, b2 ] ->
                                    Just (TreePath6 tree () ())
                                        |> Maybe.andThen (down6 b1)
                                        |> Maybe.andThen (down5 b2)
                                        |> Maybe.map config.level4.pathType
                                        |> Maybe.map JD.succeed
                                        |> Maybe.withDefault (JD.fail "Illegal path branch index")

                                [ b1, b2, b3 ] ->
                                    Just (TreePath6 tree () ())
                                        |> Maybe.andThen (down6 b1)
                                        |> Maybe.andThen (down5 b2)
                                        |> Maybe.andThen (down4 b3)
                                        |> Maybe.map config.level3.pathType
                                        |> Maybe.map JD.succeed
                                        |> Maybe.withDefault (JD.fail "Illegal path branch index")

                                [ b1, b2, b3, b4 ] ->
                                    Just (TreePath6 tree () ())
                                        |> Maybe.andThen (down6 b1)
                                        |> Maybe.andThen (down5 b2)
                                        |> Maybe.andThen (down4 b3)
                                        |> Maybe.andThen (down3 b4)
                                        |> Maybe.map config.level2.pathType
                                        |> Maybe.map JD.succeed
                                        |> Maybe.withDefault (JD.fail "Illegal path branch index")

                                [ b1, b2, b3, b4, b5 ] ->
                                    Just (TreePath6 tree () ())
                                        |> Maybe.andThen (down6 b1)
                                        |> Maybe.andThen (down5 b2)
                                        |> Maybe.andThen (down4 b3)
                                        |> Maybe.andThen (down3 b4)
                                        |> Maybe.andThen (down2 b5)
                                        |> Maybe.map config.leaf.pathType
                                        |> Maybe.map JD.succeed
                                        |> Maybe.withDefault (JD.fail "Illegal path branch index")

                                otherwise ->
                                    JD.fail <| "Illegal path length " ++ String.fromInt (List.length path)
                        )
            )


{-| -}
toRootPath : Tree6 a b c d e leaf -> TreePath6 a b c d e leaf
toRootPath tree =
    TreePath6 tree () ()


decoder1 : Decoder leaf -> Decoder (Tree1 leaf)
decoder1 leafDecoder =
    leafDecoder
        |> JD.map (\data -> Tree1 { data = data })


encode1 : (leaf -> Value) -> Tree1 leaf -> Value
encode1 leafEncode (Tree1 { data }) =
    leafEncode data


{-| -}
pathEncode1 : DecoderConfig a b c d e leaf path -> TreePath1 a b c d e leaf -> Value
pathEncode1 config ((TreePath1 tree1 idx1 ((TreePath2 tree2 idx2 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3)) as treePath2)) as treePath1) =
    JE.object
        [ ( "tree", tree6 |> encode config )
        , ( "path", [ idx5, idx4, idx3, idx2, idx1 ] |> JE.list JE.int )
        ]


{-| -}
data1 : TreePath1 a b c d e leaf -> leaf
data1 (TreePath1 (Tree1 { data }) _ _) =
    data


{-| -}
top1 : TreePath1 a b c d e leaf -> TreePath6 a b c d e leaf
top1 ((TreePath1 tree1 idx1 ((TreePath2 tree2 idx2 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3)) as treePath2)) as treePath1) =
    treePath6


{-| -}
offset1 : Int -> TreePath1 a b c d e leaf -> Maybe (TreePath1 a b c d e leaf)
offset1 dx (TreePath1 _ idx parentPath) =
    parentPath
        |> down2 (idx + dx)


{-| -}
down1 : Int -> TreePath1 a b c d e leaf -> Maybe Never
down1 _ _ =
    Nothing


{-| -}
downs1 : TreePath1 a b c d e leaf -> List Never
downs1 _ =
    []


{-| -}
up1 : TreePath1 a b c d e leaf -> Maybe (TreePath2 a b c d e leaf)
up1 ((TreePath1 tree1 idx1 ((TreePath2 tree2 idx2 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3)) as treePath2)) as treePath1) =
    Just treePath2


decoder2 : ( Decoder a, String ) -> Decoder leaf -> Decoder (Tree2 a leaf)
decoder2 ( aDecoder, aChildrenField ) leafDecoder =
    JD.oneOf
        [ JD.map2 (\data children -> Tree2 { data = data, children = children })
            (aDecoder |> JD.map Data.BranchData)
            (JD.field aChildrenField (JD.array <| decoder1 leafDecoder))
        , JD.map (\data -> Tree2 { data = data, children = Array.empty })
            (leafDecoder |> JD.map Data.LeafData)
        ]


encode2 : ( a -> List ( String, Value ), String ) -> (leaf -> Value) -> Tree2 a leaf -> Value
encode2 ( aEncoders, aChildrenField ) leafEncode (Tree2 { data, children }) =
    case data of
        Data.BranchData b ->
            JE.object <|
                ( aChildrenField, JE.array (encode1 leafEncode) children )
                    :: aEncoders b

        Data.LeafData l ->
            leafEncode l


{-| -}
pathEncode2 : DecoderConfig a b c d e leaf path -> TreePath2 a b c d e leaf -> Value
pathEncode2 config ((TreePath2 tree2 idx2 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3)) as treePath2) =
    JE.object
        [ ( "tree", tree6 |> encode config )
        , ( "path", [ idx5, idx4, idx3, idx2 ] |> JE.list JE.int )
        ]


{-| -}
data2 : TreePath2 a b c d e leaf -> Data e leaf
data2 (TreePath2 (Tree2 { data }) _ _) =
    data


{-| -}
top2 : TreePath2 a b c d e leaf -> TreePath6 a b c d e leaf
top2 ((TreePath2 tree2 idx2 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3)) as treePath2) =
    treePath6


{-| -}
offset2 : Int -> TreePath2 a b c d e leaf -> Maybe (TreePath2 a b c d e leaf)
offset2 dx (TreePath2 _ idx parentPath) =
    parentPath
        |> down3 (idx + dx)


{-| -}
down2 : Int -> TreePath2 a b c d e leaf -> Maybe (TreePath1 a b c d e leaf)
down2 idx ((TreePath2 ((Tree2 { children }) as tree) _ _) as treePath) =
    children
        |> Array.get idx
        |> Maybe.map (\childTree -> TreePath1 childTree idx treePath)


{-| -}
downs2 : TreePath2 a b c d e leaf -> List (TreePath1 a b c d e leaf)
downs2 ((TreePath2 ((Tree2 { children }) as tree) _ _) as treePath) =
    List.range 0 (Array.length children - 1)
        |> List.filterMap (\idx -> down2 idx treePath)


{-| -}
up2 : TreePath2 a b c d e leaf -> Maybe (TreePath3 a b c d e leaf)
up2 ((TreePath2 tree2 idx2 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3)) as treePath2) =
    Just treePath3


decoder3 : ( Decoder a, String ) -> ( Decoder b, String ) -> Decoder leaf -> Decoder (Tree3 a b leaf)
decoder3 ( aDecoder, aChildrenField ) ( bDecoder, bChildrenField ) leafDecoder =
    JD.oneOf
        [ JD.map2 (\data children -> Tree3 { data = data, children = children })
            (aDecoder |> JD.map Data.BranchData)
            (JD.field aChildrenField (JD.array <| decoder2 ( bDecoder, bChildrenField ) leafDecoder))
        , JD.map (\data -> Tree3 { data = data, children = Array.empty })
            (leafDecoder |> JD.map Data.LeafData)
        ]


encode3 : ( a -> List ( String, Value ), String ) -> ( b -> List ( String, Value ), String ) -> (leaf -> Value) -> Tree3 a b leaf -> Value
encode3 ( aEncoders, aChildrenField ) ( bEncoders, bChildrenField ) leafEncode (Tree3 { data, children }) =
    case data of
        Data.BranchData b ->
            JE.object <|
                ( aChildrenField, JE.array (encode2 ( bEncoders, bChildrenField ) leafEncode) children )
                    :: aEncoders b

        Data.LeafData l ->
            leafEncode l


{-| -}
pathEncode3 : DecoderConfig a b c d e leaf path -> TreePath3 a b c d e leaf -> Value
pathEncode3 config ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3) =
    JE.object
        [ ( "tree", tree6 |> encode config )
        , ( "path", [ idx5, idx4, idx3 ] |> JE.list JE.int )
        ]


{-| -}
data3 : TreePath3 a b c d e leaf -> Data d leaf
data3 (TreePath3 (Tree3 { data }) _ _) =
    data


{-| -}
top3 : TreePath3 a b c d e leaf -> TreePath6 a b c d e leaf
top3 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3) =
    treePath6


{-| -}
offset3 : Int -> TreePath3 a b c d e leaf -> Maybe (TreePath3 a b c d e leaf)
offset3 dx (TreePath3 _ idx parentPath) =
    parentPath
        |> down4 (idx + dx)


{-| -}
down3 : Int -> TreePath3 a b c d e leaf -> Maybe (TreePath2 a b c d e leaf)
down3 idx ((TreePath3 ((Tree3 { children }) as tree) _ _) as treePath) =
    children
        |> Array.get idx
        |> Maybe.map (\childTree -> TreePath2 childTree idx treePath)


{-| -}
downs3 : TreePath3 a b c d e leaf -> List (TreePath2 a b c d e leaf)
downs3 ((TreePath3 ((Tree3 { children }) as tree) _ _) as treePath) =
    List.range 0 (Array.length children - 1)
        |> List.filterMap (\idx -> down3 idx treePath)


{-| -}
up3 : TreePath3 a b c d e leaf -> Maybe (TreePath4 a b c d e leaf)
up3 ((TreePath3 tree3 idx3 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4)) as treePath3) =
    Just treePath4


decoder4 : ( Decoder a, String ) -> ( Decoder b, String ) -> ( Decoder c, String ) -> Decoder leaf -> Decoder (Tree4 a b c leaf)
decoder4 ( aDecoder, aChildrenField ) ( bDecoder, bChildrenField ) ( cDecoder, cChildrenField ) leafDecoder =
    JD.oneOf
        [ JD.map2 (\data children -> Tree4 { data = data, children = children })
            (aDecoder |> JD.map Data.BranchData)
            (JD.field aChildrenField (JD.array <| decoder3 ( bDecoder, bChildrenField ) ( cDecoder, cChildrenField ) leafDecoder))
        , JD.map (\data -> Tree4 { data = data, children = Array.empty })
            (leafDecoder |> JD.map Data.LeafData)
        ]


encode4 : ( a -> List ( String, Value ), String ) -> ( b -> List ( String, Value ), String ) -> ( c -> List ( String, Value ), String ) -> (leaf -> Value) -> Tree4 a b c leaf -> Value
encode4 ( aEncoders, aChildrenField ) ( bEncoders, bChildrenField ) ( cEncoders, cChildrenField ) leafEncode (Tree4 { data, children }) =
    case data of
        Data.BranchData b ->
            JE.object <|
                ( aChildrenField, JE.array (encode3 ( bEncoders, bChildrenField ) ( cEncoders, cChildrenField ) leafEncode) children )
                    :: aEncoders b

        Data.LeafData l ->
            leafEncode l


{-| -}
pathEncode4 : DecoderConfig a b c d e leaf path -> TreePath4 a b c d e leaf -> Value
pathEncode4 config ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4) =
    JE.object
        [ ( "tree", tree6 |> encode config )
        , ( "path", [ idx5, idx4 ] |> JE.list JE.int )
        ]


{-| -}
data4 : TreePath4 a b c d e leaf -> Data c leaf
data4 (TreePath4 (Tree4 { data }) _ _) =
    data


{-| -}
top4 : TreePath4 a b c d e leaf -> TreePath6 a b c d e leaf
top4 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4) =
    treePath6


{-| -}
offset4 : Int -> TreePath4 a b c d e leaf -> Maybe (TreePath4 a b c d e leaf)
offset4 dx (TreePath4 _ idx parentPath) =
    parentPath
        |> down5 (idx + dx)


{-| -}
down4 : Int -> TreePath4 a b c d e leaf -> Maybe (TreePath3 a b c d e leaf)
down4 idx ((TreePath4 ((Tree4 { children }) as tree) _ _) as treePath) =
    children
        |> Array.get idx
        |> Maybe.map (\childTree -> TreePath3 childTree idx treePath)


{-| -}
downs4 : TreePath4 a b c d e leaf -> List (TreePath3 a b c d e leaf)
downs4 ((TreePath4 ((Tree4 { children }) as tree) _ _) as treePath) =
    List.range 0 (Array.length children - 1)
        |> List.filterMap (\idx -> down4 idx treePath)


{-| -}
up4 : TreePath4 a b c d e leaf -> Maybe (TreePath5 a b c d e leaf)
up4 ((TreePath4 tree4 idx4 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5)) as treePath4) =
    Just treePath5


decoder5 : ( Decoder a, String ) -> ( Decoder b, String ) -> ( Decoder c, String ) -> ( Decoder d, String ) -> Decoder leaf -> Decoder (Tree5 a b c d leaf)
decoder5 ( aDecoder, aChildrenField ) ( bDecoder, bChildrenField ) ( cDecoder, cChildrenField ) ( dDecoder, dChildrenField ) leafDecoder =
    JD.oneOf
        [ JD.map2 (\data children -> Tree5 { data = data, children = children })
            (aDecoder |> JD.map Data.BranchData)
            (JD.field aChildrenField (JD.array <| decoder4 ( bDecoder, bChildrenField ) ( cDecoder, cChildrenField ) ( dDecoder, dChildrenField ) leafDecoder))
        , JD.map (\data -> Tree5 { data = data, children = Array.empty })
            (leafDecoder |> JD.map Data.LeafData)
        ]


encode5 : ( a -> List ( String, Value ), String ) -> ( b -> List ( String, Value ), String ) -> ( c -> List ( String, Value ), String ) -> ( d -> List ( String, Value ), String ) -> (leaf -> Value) -> Tree5 a b c d leaf -> Value
encode5 ( aEncoders, aChildrenField ) ( bEncoders, bChildrenField ) ( cEncoders, cChildrenField ) ( dEncoders, dChildrenField ) leafEncode (Tree5 { data, children }) =
    case data of
        Data.BranchData b ->
            JE.object <|
                ( aChildrenField, JE.array (encode4 ( bEncoders, bChildrenField ) ( cEncoders, cChildrenField ) ( dEncoders, dChildrenField ) leafEncode) children )
                    :: aEncoders b

        Data.LeafData l ->
            leafEncode l


{-| -}
pathEncode5 : DecoderConfig a b c d e leaf path -> TreePath5 a b c d e leaf -> Value
pathEncode5 config ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5) =
    JE.object
        [ ( "tree", tree6 |> encode config )
        , ( "path", [ idx5 ] |> JE.list JE.int )
        ]


{-| -}
data5 : TreePath5 a b c d e leaf -> Data b leaf
data5 (TreePath5 (Tree5 { data }) _ _) =
    data


{-| -}
top5 : TreePath5 a b c d e leaf -> TreePath6 a b c d e leaf
top5 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5) =
    treePath6


{-| -}
offset5 : Int -> TreePath5 a b c d e leaf -> Maybe (TreePath5 a b c d e leaf)
offset5 dx (TreePath5 _ idx parentPath) =
    parentPath
        |> down6 (idx + dx)


{-| -}
down5 : Int -> TreePath5 a b c d e leaf -> Maybe (TreePath4 a b c d e leaf)
down5 idx ((TreePath5 ((Tree5 { children }) as tree) _ _) as treePath) =
    children
        |> Array.get idx
        |> Maybe.map (\childTree -> TreePath4 childTree idx treePath)


{-| -}
downs5 : TreePath5 a b c d e leaf -> List (TreePath4 a b c d e leaf)
downs5 ((TreePath5 ((Tree5 { children }) as tree) _ _) as treePath) =
    List.range 0 (Array.length children - 1)
        |> List.filterMap (\idx -> down5 idx treePath)


{-| -}
up5 : TreePath5 a b c d e leaf -> Maybe (TreePath6 a b c d e leaf)
up5 ((TreePath5 tree5 idx5 ((TreePath6 tree6 _ _) as treePath6)) as treePath5) =
    Just treePath6


decoder6 : ( Decoder a, String ) -> ( Decoder b, String ) -> ( Decoder c, String ) -> ( Decoder d, String ) -> ( Decoder e, String ) -> Decoder leaf -> Decoder (Tree6 a b c d e leaf)
decoder6 ( aDecoder, aChildrenField ) ( bDecoder, bChildrenField ) ( cDecoder, cChildrenField ) ( dDecoder, dChildrenField ) ( eDecoder, eChildrenField ) leafDecoder =
    JD.oneOf
        [ JD.map2 (\data children -> Tree6 { data = data, children = children })
            (aDecoder |> JD.map Data.BranchData)
            (JD.field aChildrenField (JD.array <| decoder5 ( bDecoder, bChildrenField ) ( cDecoder, cChildrenField ) ( dDecoder, dChildrenField ) ( eDecoder, eChildrenField ) leafDecoder))
        , JD.map (\data -> Tree6 { data = data, children = Array.empty })
            (leafDecoder |> JD.map Data.LeafData)
        ]


encode6 : ( a -> List ( String, Value ), String ) -> ( b -> List ( String, Value ), String ) -> ( c -> List ( String, Value ), String ) -> ( d -> List ( String, Value ), String ) -> ( e -> List ( String, Value ), String ) -> (leaf -> Value) -> Tree6 a b c d e leaf -> Value
encode6 ( aEncoders, aChildrenField ) ( bEncoders, bChildrenField ) ( cEncoders, cChildrenField ) ( dEncoders, dChildrenField ) ( eEncoders, eChildrenField ) leafEncode (Tree6 { data, children }) =
    case data of
        Data.BranchData b ->
            JE.object <|
                ( aChildrenField, JE.array (encode5 ( bEncoders, bChildrenField ) ( cEncoders, cChildrenField ) ( dEncoders, dChildrenField ) ( eEncoders, eChildrenField ) leafEncode) children )
                    :: aEncoders b

        Data.LeafData l ->
            leafEncode l


{-| -}
pathEncode6 : DecoderConfig a b c d e leaf path -> TreePath6 a b c d e leaf -> Value
pathEncode6 config ((TreePath6 tree6 _ _) as treePath6) =
    JE.object
        [ ( "tree", tree6 |> encode config )
        , ( "path", [] |> JE.list JE.int )
        ]


{-| -}
data6 : TreePath6 a b c d e leaf -> Data a leaf
data6 (TreePath6 (Tree6 { data }) _ _) =
    data


{-| -}
top6 : TreePath6 a b c d e leaf -> TreePath6 a b c d e leaf
top6 ((TreePath6 tree6 _ _) as treePath6) =
    treePath6


{-| -}
offset6 : Int -> TreePath6 a b c d e leaf -> Maybe (TreePath6 a b c d e leaf)
offset6 dx (TreePath6 _ idx parentPath) =
    Nothing


{-| -}
down6 : Int -> TreePath6 a b c d e leaf -> Maybe (TreePath5 a b c d e leaf)
down6 idx ((TreePath6 ((Tree6 { children }) as tree) _ _) as treePath) =
    children
        |> Array.get idx
        |> Maybe.map (\childTree -> TreePath5 childTree idx treePath)


{-| -}
downs6 : TreePath6 a b c d e leaf -> List (TreePath5 a b c d e leaf)
downs6 ((TreePath6 ((Tree6 { children }) as tree) _ _) as treePath) =
    List.range 0 (Array.length children - 1)
        |> List.filterMap (\idx -> down6 idx treePath)


{-| -}
up6 : TreePath6 a b c d e leaf -> Maybe Never
up6 ((TreePath6 tree6 _ _) as treePath6) =
    Nothing
