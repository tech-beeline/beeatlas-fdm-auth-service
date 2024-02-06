package ru.beeline.fdmauth.dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.Getter;
import lombok.Setter;
import ru.beeline.fdmauth.domain.UserProfile;
import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Getter
@Setter
public class UserProfileDTO {

    private Long id;

    @JsonProperty("id_ext")
    private String idExt;

    @JsonProperty("full_name")
    private String fullName;

    private String login;

    @JsonProperty("last_login")
    private Date lastLogin;

    private String email;

    private List<RoleDTO> roles;

    public UserProfileDTO(String idExt, String fullName, String login, String email) {
        this.idExt = idExt;
        this.fullName = fullName;
        this.login = login;
        this.email = email;
    }

    public UserProfileDTO(UserProfile userProfile) {
        this.id = userProfile.getId();
        this.idExt = userProfile.getIdExt();
        this.fullName = userProfile.getFullName();
        this.login = userProfile.getLogin();
        this.lastLogin = userProfile.getLastLogin();
        this.email = userProfile.getEmail();
        this.roles = RoleDTO.convert(userProfile.getUserRoles());
    }

    public static List<UserProfileDTO> convert(List<UserProfile> users) {
        return users.stream()
                .map(UserProfileDTO::new)
                .collect(Collectors.toList());
    }
}
