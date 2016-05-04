package com.cfgmaster.server;
import java.util.HashMap;

public class Dossier extends BaseClass {
    
    public Dossier getParent() {
        return( this.mParent );
    }
    public void setParent( Dossier pParent ) {
        this.mParent = pParent;
    }
    public static boolean isReadableByUser( User pUser ) {
        return( true );
    }
    public static boolean isMutableByUser( User pUser ) {
        return( true );
    }
    private Dossier mParent;
    private HashMap mMetadata;    
}
