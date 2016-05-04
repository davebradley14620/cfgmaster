package com.cfgmaster.server;

import java.util.Date;
import java.util.Iterator;
import java.util.List;

public class UserGroup extends User {
    public UserGroup( int pId, Date pTimestamp, int pImageId, String pName, List<User> pUsers ) {
        super(pId, pTimestamp, pImageId, pName );
        this.mUsers = pUsers;
    }
    public List<User> getUsers() {
        return( this.mUsers );
    }
    public void setUsers( List<User> pUsers ) {
        this.mUsers = pUsers;
    }
    public boolean isUserAMember(User pUser) {
        Iterator<User> it = mUsers.iterator();
        while( it.hasNext() ) {
            User u = it.next();
            if ( u.getId() == pUser.getId() ) {
                return( true );
            }
        }
        return( false );
    }

    public void addUser( User pUser ) {
        this.mUsers.add(pUser);
    }
    public int getUserCount() {
        return( this.mUsers.size() );
    }
    private List<User> mUsers;
}
