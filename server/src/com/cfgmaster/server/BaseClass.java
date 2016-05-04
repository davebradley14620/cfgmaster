package com.cfgmaster.server;
import java.util.Date;

public class BaseClass {
    public BaseClass() {
        super();
    }
    public BaseClass( int pId, Date pTimestamp, int pImageId) {
        this.mId = pId;
        this.mTimestamp = pTimestamp;
        this.mImageId = pImageId;
    }
    
    public int getId() {
        return( this.mId );
    }
    public Date getTimestamp() {
        return( this.mTimestamp );
    }
    public int getImageId() {
        return( this.mImageId );
    }
    private int mId;
    private Date mTimestamp;
    private int mImageId;
}