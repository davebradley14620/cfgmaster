package com.cfgmaster.server;

import java.util.Date;

public class User extends BaseClass {
    public User( int pId, Date pTimestamp, int pImageId, String pName ) {
        super(pId,pTimestamp,pImageId);
        this.mName = pName;
    }
    public String getName() {
        return( this.mName );
    }
    private String mName;
}
